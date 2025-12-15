import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';

/// Conversations list screen
class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(conversationsProvider.notifier).loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isAuthenticatedProvider);
    final l10n = context.l10n;

    if (!isLoggedIn) {
      return _buildLoginPrompt(context, l10n);
    }

    final conversationsState = ref.watch(conversationsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isRtl = context.isRtl;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('conversations.title')),
        actions: [
          IconButton(
            onPressed: () =>
                ref.read(conversationsProvider.notifier).loadConversations(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(conversationsState, currentUser?.id ?? 0, isRtl, l10n),
    );
  }

  Widget _buildBody(
    ConversationsState state,
    int currentUserId,
    bool isRtl,
    AppLocalizations l10n,
  ) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(conversationsProvider.notifier).loadConversations(),
              child: Text(l10n.tr('retry')),
            ),
          ],
        ),
      );
    }

    if (state.conversations.isEmpty) {
      return _buildEmptyState(context, l10n);
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(conversationsProvider.notifier).loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          return _buildConversationTile(
            context,
            state.conversations[index],
            currentUserId,
            isRtl,
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, AppLocalizations l10n) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.tr('conversations.title'))),
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
              FilledButton(
                onPressed: () => context.push(Routes.login),
                child: Text(l10n.tr('login')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
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
              onPressed: () => context.go(Routes.home),
              icon: const Icon(Icons.explore_rounded),
              label: Text(l10n.tr('browseProducts')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    int currentUserId,
    bool isRtl,
  ) {
    final isCustomer = conversation.customerId == currentUserId;
    final displayName = isCustomer
        ? conversation.project?.getLocalizedName(isRtl ? 'ar' : 'en') ??
            'Unknown'
        : conversation.customer?.fullName ?? 'Unknown';
    final avatarUrl = isCustomer
        ? conversation.project?.logoUrl
        : conversation.customer?.avatarUrl;
    final hasUnread = conversation.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnread ? AppColors.primary.withAlpha(13) : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: hasUnread
            ? Border.all(color: AppColors.primary.withAlpha(51))
            : null,
      ),
      child: ListTile(
        onTap: () {
          context.push(
            Routes.chat
                .replaceFirst(':conversationId', conversation.id.toString()),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: ApiEndpoints.imageUrl(avatarUrl),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimeAgo(
                  conversation.lastMessageAt ?? conversation.createdAt, isRtl),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color:
                        hasUnread ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
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
                  conversation.lastMessage
                          ?.getLocalizedPreview(isRtl ? 'ar' : 'en') ??
                      '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (conversation.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  String _formatTimeAgo(DateTime date, bool isRtl) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return isRtl ? 'الآن' : 'now';
    }
    if (diff.inMinutes < 60) {
      return isRtl ? '${diff.inMinutes}د' : '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return isRtl ? '${diff.inHours}س' : '${diff.inHours}h';
    }
    if (diff.inDays < 7) {
      return isRtl ? '${diff.inDays}ي' : '${diff.inDays}d';
    }
    return '${date.day}/${date.month}';
  }
}
