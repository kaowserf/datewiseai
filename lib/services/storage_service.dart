import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_thread.dart';
import '../models/tier.dart';

/// Browser-localStorage-style persistence (PRD: all data stays on the device,
/// no cloud). On web, [SharedPreferences] is backed by window.localStorage.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _kTier = 'dw_tier';
  static const _kThreads = 'dw_threads';
  static const _kOnboarded = 'dw_onboarded';

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Tier ---------------------------------------------------------------

  SubscriptionTier? loadTier() {
    final id = _prefs.getString(_kTier);
    if (id == null) return null;
    return SubscriptionTier.fromId(id);
  }

  Future<void> saveTier(SubscriptionTier tier) =>
      _prefs.setString(_kTier, tier.name);

  bool get hasOnboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  // --- Threads ------------------------------------------------------------

  List<ChatThread> loadThreads() {
    final raw = _prefs.getString(_kThreads);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => ChatThread.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveThreads(List<ChatThread> threads) {
    final raw = jsonEncode(threads.map((t) => t.toJson()).toList());
    return _prefs.setString(_kThreads, raw);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_kThreads);
    await _prefs.remove(_kTier);
    await _prefs.remove(_kOnboarded);
  }
}
