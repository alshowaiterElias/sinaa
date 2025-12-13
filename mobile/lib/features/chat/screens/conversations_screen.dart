// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/auth_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    final l10n = context.l10n;

    if (!isLoggedIn) {
      return _buildLoginPrompt(context);
    }

    // TODO: Replace with actual conversations data
    final conversations = <_ConversationItem>[];
    final isEmpty = conversations.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('conversations.title')),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Search conversations
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: isEmpty
          ? _buildEmptyState(context)
          : _buildConversationsList(context, conversations),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('conversations.title')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withAlpha(38),
                      AppColors.secondary.withAlpha(13),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 70,
                  color: AppColors.secondary.withAlpha(128),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                l10n.tr('loginForChat'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tr('loginForChatMessage'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(102),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => context.push(Routes.login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                  ),
                  child: Text(l10n.tr('login')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary.withAlpha(38),
                    AppColors.secondary.withAlpha(13),
                  ],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 70,
                color: AppColors.secondary.withAlpha(128),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.tr('noConversations'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.tr('noConversationsMessage'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to home/search
              },
              icon: const Icon(Icons.explore_rounded),
              label: Text(l10n.tr('browseProducts')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    List<_ConversationItem> conversations,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        return _buildConversationTile(context, conversations[index]);
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    _ConversationItem conversation,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: conversation.hasUnread
            ? AppColors.primary.withAlpha(13)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: conversation.hasUnread
            ? Border.all(color: AppColors.primary.withAlpha(51))
            : null,
      ),
      child: ListTile(
        onTap: () {
          // TODO: Navigate to chat
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: conversation.projectImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        conversation.projectImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
            if (conversation.isOnline)
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.projectName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: conversation.hasUnread
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              conversation.timeAgo,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: conversation.hasUnread
                        ? AppColors.primary
                        : AppColors.textTertiary,
                    fontWeight: conversation.hasUnread
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.lastMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: conversation.hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: conversation.hasUnread
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (conversation.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Temporary data class - parameters will be used when real data is connected
class _ConversationItem {
  final String id;
  final String projectId;
  final String projectName;
  final String? projectImage;
  final String lastMessage;
  final String timeAgo;
  final bool hasUnread;
  final int unreadCount;
  final bool isOnline;

  _ConversationItem({
    required this.id,
    required this.projectId,
    required this.projectName,
    this.projectImage,
    required this.lastMessage,
    required this.timeAgo,
    this.hasUnread = false,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}
