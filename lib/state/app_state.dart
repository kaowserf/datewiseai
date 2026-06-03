import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../app_flags.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/photo_analysis.dart';
import '../models/tier.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/persona.dart';
import '../services/storage_service.dart';

/// Central app state: subscription tier, coaching threads, and orchestration of
/// streaming AI replies. Backed by [StorageService] for local persistence and
/// an [AIService] (real Gemini or offline mock) for coaching.
class AppState extends ChangeNotifier {
  AppState({required StorageService storage, required AIService ai})
      : _storage = storage,
        _ai = ai {
    _load();
  }

  final StorageService _storage;
  final AIService _ai;
  final _uuid = const Uuid();

  // --- Tier ---------------------------------------------------------------

  SubscriptionTier? _tier;
  SubscriptionTier? get tier => _tier;
  bool get hasTier => _tier != null;
  TierInfo get tierInfo => TierInfo.of(_tier ?? SubscriptionTier.spark);

  String get providerLabel => _ai.providerLabel;

  bool can(Capability capability) => tierInfo.can(capability);

  /// Whether the AI Photo Coach is usable. Normally Magnet-only, but the
  /// testing flag unlocks it on every tier (see [AppFlags]).
  bool get photoCoachUnlocked =>
      AppFlags.unlockPhotoCoachForTesting || can(Capability.photoCoach);

  // --- User profile -------------------------------------------------------

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool get hasProfile => _profile != null;

  /// Saves the onboarding profile and creates the first personalised thread.
  Future<void> completeOnboarding(UserProfile profile) async {
    _profile = profile;
    await _storage.saveProfile(profile);
    await ensureStarterThread();
    notifyListeners();
  }

  /// Creates the initial "Profile Setup" thread if the user has none yet.
  Future<void> ensureStarterThread() async {
    if (_threads.isEmpty) {
      await createThread(title: 'Profile Setup', greet: true);
    }
  }

  // --- Threads ------------------------------------------------------------

  final List<ChatThread> _threads = [];
  List<ChatThread> get threads => List.unmodifiable(_threads);

  String? _activeThreadId;
  String? get activeThreadId => _activeThreadId;

  ChatThread? get activeThread {
    if (_activeThreadId == null) return null;
    for (final t in _threads) {
      if (t.id == _activeThreadId) return t;
    }
    return null;
  }

  bool _isResponding = false;
  bool get isResponding => _isResponding;

  void _load() {
    _tier = _storage.loadTier();
    _profile = _storage.loadProfile();
    _threads
      ..clear()
      ..addAll(_storage.loadThreads());
    _threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (_threads.isNotEmpty) _activeThreadId = _threads.first.id;
    notifyListeners();
  }

  // --- Tier selection -----------------------------------------------------

  /// Records the chosen tier. The starter thread is created after onboarding
  /// (see [completeOnboarding]) so the greeting can be personalised.
  Future<void> selectTier(SubscriptionTier tier) async {
    _tier = tier;
    await _storage.saveTier(tier);
    notifyListeners();
  }

  // --- Thread CRUD --------------------------------------------------------

  Future<ChatThread> createThread({String? title, bool greet = true}) async {
    final now = _now();
    final thread = ChatThread(
      id: _uuid.v4(),
      title: title ?? 'New conversation',
      createdAt: now,
      updatedAt: now,
    );
    if (greet) {
      thread.messages.add(
        ChatMessage(
          id: _uuid.v4(),
          role: MessageRole.coach,
          text: CoachPersona.greeting(
            _tier ?? SubscriptionTier.spark,
            profile: _profile,
          ),
          createdAt: now,
        ),
      );
    }
    _threads.insert(0, thread);
    _activeThreadId = thread.id;
    await _persist();
    notifyListeners();
    return thread;
  }

  void selectThread(String id) {
    _activeThreadId = id;
    notifyListeners();
  }

  Future<void> renameThread(String id, String title) async {
    final t = _threadById(id);
    if (t == null) return;
    t.title = title.trim().isEmpty ? t.title : title.trim();
    await _persist();
    notifyListeners();
  }

  Future<void> deleteThread(String id) async {
    _threads.removeWhere((t) => t.id == id);
    if (_activeThreadId == id) {
      _activeThreadId = _threads.isEmpty ? null : _threads.first.id;
    }
    await _persist();
    notifyListeners();
  }

  // --- Messaging ----------------------------------------------------------

  /// Sends a user message (optionally with a photo) and streams the coach reply.
  Future<void> sendMessage({String text = '', String? imageBase64}) async {
    if (_isResponding) return;
    final tier = _tier ?? SubscriptionTier.spark;

    var thread = activeThread;
    thread ??= await createThread(title: 'New conversation', greet: false);

    final now = _now();
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.user,
      text: text.trim(),
      createdAt: now,
      imageBase64: imageBase64,
    );
    thread.messages.add(userMsg);
    thread.updatedAt = now;
    _autoTitle(thread);
    _bumpToTop(thread);
    notifyListeners();

    // Photo coach: produce a structured analysis card (Magnet, or any tier
    // while the testing flag is on).
    if (imageBase64 != null && photoCoachUnlocked) {
      await _runPhotoAnalysis(thread, imageBase64, text);
      return;
    }

    await _streamCoachReply(thread, tier);
  }

  Future<void> _streamCoachReply(ChatThread thread, SubscriptionTier tier) async {
    _isResponding = true;
    final coachMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.coach,
      text: '',
      createdAt: _now(),
      isStreaming: true,
    );
    thread.messages.add(coachMsg);
    notifyListeners();

    try {
      await for (final chunk in _ai.streamReply(
        history: List.of(thread.messages.where((m) => !m.isStreaming)),
        tier: tier,
      )) {
        coachMsg.text += chunk;
        notifyListeners();
      }
    } catch (_) {
      coachMsg.text = coachMsg.text.isEmpty
          ? "Something interrupted me there — try sending that again?"
          : coachMsg.text;
    } finally {
      coachMsg.isStreaming = false;
      _isResponding = false;
      thread.updatedAt = _now();
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _runPhotoAnalysis(
    ChatThread thread,
    String imageBase64,
    String note,
  ) async {
    _isResponding = true;
    final coachMsg = ChatMessage(
      id: _uuid.v4(),
      role: MessageRole.coach,
      text: 'Analysing your photo…',
      createdAt: _now(),
      isStreaming: true,
    );
    thread.messages.add(coachMsg);
    notifyListeners();

    try {
      // When testing-unlocked on a lower tier, present as Magnet so the
      // backend (which gates on tier) accepts the request.
      final effectiveTier = photoCoachUnlocked && !can(Capability.photoCoach)
          ? SubscriptionTier.magnet
          : (_tier ?? SubscriptionTier.magnet);
      final PhotoAnalysis analysis = await _ai.analyzePhoto(
        imageBase64: imageBase64,
        tier: effectiveTier,
        userNote: note,
      );
      final verdict = analysis.verdict.label;
      thread.messages.remove(coachMsg);
      thread.messages.add(
        ChatMessage(
          id: _uuid.v4(),
          role: MessageRole.coach,
          text:
              '**${analysis.overallScore}/10 · $verdict** — ${analysis.headline}',
          createdAt: _now(),
          analysis: analysis,
        ),
      );
    } catch (_) {
      coachMsg.text = "I couldn't read that image — try a JPG or PNG under ~5MB?";
      coachMsg.isStreaming = false;
    } finally {
      _isResponding = false;
      thread.updatedAt = _now();
      await _persist();
      notifyListeners();
    }
  }

  // --- Helpers ------------------------------------------------------------

  void _autoTitle(ChatThread thread) {
    final isDefault = thread.title == 'New conversation';
    final firstUser = thread.messages.firstWhere(
      (m) => m.isUser && m.text.trim().isNotEmpty,
      orElse: () => ChatMessage(
        id: '',
        role: MessageRole.user,
        text: '',
        createdAt: _now(),
      ),
    );
    if (isDefault && firstUser.text.trim().isNotEmpty) {
      final words = firstUser.text.trim().split(RegExp(r'\s+'));
      thread.title = words.take(5).join(' ');
      if (words.length > 5) thread.title += '…';
    }
  }

  void _bumpToTop(ChatThread thread) {
    _threads.removeWhere((t) => t.id == thread.id);
    _threads.insert(0, thread);
  }

  ChatThread? _threadById(String id) {
    for (final t in _threads) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> _persist() => _storage.saveThreads(_threads);

  Future<void> resetAll() async {
    await _storage.clearAll();
    _threads.clear();
    _activeThreadId = null;
    _tier = null;
    notifyListeners();
  }

  // Date.now() is unavailable in some sandboxes but fine in-app at runtime.
  DateTime _now() => DateTime.now();
}
