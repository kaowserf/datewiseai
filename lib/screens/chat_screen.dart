import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_thread.dart';
import '../models/tier.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/chat/chat_input.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/suggestion_chips.dart';
import '../widgets/chat/thread_sidebar.dart';
import 'landing_screen.dart';

/// AI coaching chat (PRD section 5.2): threaded conversations with DateWise AI,
/// a persistent sidebar on wide screens, and a Drawer on mobile.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSend(BuildContext context, {String text = '', String? imageBase64}) {
    context.read<AppState>().sendMessage(text: text, imageBase64: imageBase64);
    _scrollToBottom();
  }

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const _UpgradeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final state = context.watch<AppState>();

    // Auto-scroll as the active thread grows / streams.
    _scrollToBottom();

    final chatArea = _ChatArea(
      key: ValueKey(state.activeThreadId),
      thread: state.activeThread,
      scrollController: _scrollController,
      isResponding: state.isResponding,
      canSendPhoto: state.photoCoachUnlocked,
      onSend: ({String text = '', String? imageBase64}) =>
          _handleSend(context, text: text, imageBase64: imageBase64),
      onPhotoBlocked: () => _showUpgradeSheet(context),
      onOpenMenu: isWide ? null : () => _scaffoldKey.currentState?.openDrawer(),
      onNewThread: () => context.read<AppState>().createThread(),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWide ? null : const Drawer(child: ThreadSidebar()),
      body: Row(
        children: [
          if (isWide) ...[
            const ThreadSidebar(),
            const VerticalDivider(width: 1),
          ],
          Expanded(child: chatArea),
        ],
      ),
    );
  }
}

class _ChatArea extends StatelessWidget {
  const _ChatArea({
    super.key,
    required this.thread,
    required this.scrollController,
    required this.isResponding,
    required this.canSendPhoto,
    required this.onSend,
    required this.onPhotoBlocked,
    required this.onOpenMenu,
    required this.onNewThread,
  });

  final ChatThread? thread;
  final ScrollController scrollController;
  final bool isResponding;
  final bool canSendPhoto;
  final void Function({String text, String? imageBase64}) onSend;
  final VoidCallback onPhotoBlocked;
  final VoidCallback? onOpenMenu;
  final VoidCallback onNewThread;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    // A conversation the user hasn't replied to yet shows the welcome state
    // and starter prompts (mirrors the PRD's coaching entry points).
    final isFresh =
        thread != null && !thread!.messages.any((m) => m.isUser);

    return Column(
      children: [
        _TopBar(
          title: thread?.title ?? 'DateWise AI',
          subtitle: 'with your coach · ${state.tierInfo.name}',
          onOpenMenu: onOpenMenu,
        ),
        const Divider(height: 1),
        Expanded(
          child: thread == null
              ? _NoThread(onNewThread: onNewThread)
              : isFresh
                  ? const _WelcomeState()
                  : ListView.builder(
                      controller: scrollController,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      itemCount: thread!.messages.length,
                      itemBuilder: (context, i) =>
                          MessageBubble(message: thread!.messages[i]),
                    ),
        ),
        // Starter prompts while the conversation is fresh.
        if (isFresh && !isResponding)
          SuggestionChips(
            canSendPhoto: canSendPhoto,
            onPhotoBlocked: onPhotoBlocked,
            onSelect: (text) => onSend(text: text),
          ),
        ChatInput(
          enabled: !isResponding && thread != null,
          canSendPhoto: canSendPhoto,
          onPhotoBlocked: onPhotoBlocked,
          onSend: onSend,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onOpenMenu,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onOpenMenu != null)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: onOpenMenu,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Back to home',
              icon: const Icon(Icons.home_outlined),
              onPressed: () {
                // ChatScreen is shown as the app's `home` for returning users,
                // so there's nothing to pop — push the landing page instead.
                // (Its app bar auto-shows a back arrow to return here.)
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LandingScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoThread extends StatelessWidget {
  const _NoThread({required this.onNewThread});
  final VoidCallback onNewThread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: AppColors.romanticGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Start a conversation', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Your coach is ready when you are.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: onNewThread,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New conversation'),
          ),
        ],
      ),
    );
  }
}

/// Centered welcome shown for a fresh conversation, above the starter chips.
class _WelcomeState extends StatelessWidget {
  const _WelcomeState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: AppColors.romanticGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Hey gorgeous. What are we fixing today?',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask about your bio, openers, mid-conversation panic, or anything '
              'dating-related. Pick a starter below or just type.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final theme = Theme.of(context);
    final magnet = TierInfo.magnet;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Unlock the AI Photo Coach',
                  style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Photo scoring, KEEP / RESHOOT / DELETE verdicts, and match-rate '
            'predictions are part of the Magnet plan (${magnet.priceLabel}/wk).',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Not now'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await state.selectTier(SubscriptionTier.magnet);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Upgrade to Magnet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
