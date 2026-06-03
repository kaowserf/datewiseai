import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_thread.dart';
import '../../models/tier.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../common/brand_mark.dart';

/// Sidebar listing coaching threads with create / rename / delete (PRD 5.4).
/// Rendered persistently on wide layouts and inside a Drawer on mobile.
class ThreadSidebar extends StatelessWidget {
  const ThreadSidebar({super.key, this.onThreadSelected});

  /// Called after a thread is selected/created so a Drawer host can close.
  final VoidCallback? onThreadSelected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const BrandMark(),
                const Spacer(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await context.read<AppState>().createThread();
                  onThreadSelected?.call();
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text('New conversation'),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          Expanded(
            child: state.threads.isEmpty
                ? const _EmptyThreads()
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: state.threads.length,
                    itemBuilder: (context, i) {
                      final thread = state.threads[i];
                      return _ThreadTile(
                        thread: thread,
                        selected: thread.id == state.activeThreadId,
                        onTap: () {
                          context.read<AppState>().selectThread(thread.id);
                          onThreadSelected?.call();
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          _TierFooter(tier: state.tierInfo, provider: state.providerLabel),
        ],
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({
    required this.thread,
    required this.selected,
    required this.onTap,
  });

  final ChatThread thread;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        leading: Icon(
          Icons.forum_outlined,
          size: 18,
          color: selected ? AppColors.primary : AppColors.textMuted,
        ),
        title: Text(
          thread.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          thread.preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, size: 18),
          onSelected: (value) {
            if (value == 'rename') {
              _rename(context);
            } else if (value == 'delete') {
              _confirmDelete(context);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: thread.title);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Conversation name'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      await context.read<AppState>().renameThread(thread.id, result);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text('“${thread.title}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD64545)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().deleteThread(thread.id);
    }
  }
}

class _EmptyThreads extends StatelessWidget {
  const _EmptyThreads();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No conversations yet.\nStart one to meet your coach.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _TierFooter extends StatelessWidget {
  const _TierFooter({required this.tier, required this.provider});
  final TierInfo tier;
  final String provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: tier.accentColor.withValues(alpha: 0.18),
            child: Icon(Icons.workspace_premium_rounded,
                size: 16, color: tier.accentColor),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tier.name} plan',
                    style: theme.textTheme.labelLarge),
                Text(
                  provider,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
