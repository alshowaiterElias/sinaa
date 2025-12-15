import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/transaction_provider.dart';
import '../../../data/repositories/project_repository.dart';
import 'message_bubble.dart';
import 'chat_input.dart';

/// Chat screen for a single conversation
class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider(widget.conversationId).notifier).loadMessages();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);
    final isRtl = context.isRtl;
    final l10n = context.l10n;

    final conversation = chatState.conversation;
    final displayName = conversation != null
        ? (currentUser?.id == conversation.customerId
            ? (isRtl
                ? conversation.project?.nameAr
                : conversation.project?.name)
            : conversation.customer?.fullName)
        : l10n.tr('chat');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(displayName ?? '', chatState, isRtl),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading && chatState.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chatState.error != null && chatState.messages.isEmpty
                    ? _buildError(chatState.error!, l10n)
                    : _buildMessageList(chatState, currentUser?.id ?? 0),
          ),
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onTypingChanged: _onTypingChanged,
            isSending: chatState.isSending,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title, ChatState state, bool isRtl) {
    final conversation = state.conversation;
    final avatarUrl = conversation?.project?.logoUrl;

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceVariant,
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? Image.network(
                    ApiEndpoints.imageUrl(avatarUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.store, color: AppColors.textTertiary),
                  )
                : const Icon(Icons.store, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.typingUsers.isNotEmpty)
                  Text(
                    context.l10n.tr('typing'),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Rating request button
        IconButton(
          icon: const Icon(Icons.star_rate_outlined),
          tooltip: isRtl ? 'طلب تقييم' : 'Request Rating',
          onPressed: () => _showRatingRequestDialog(context, isRtl),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'view_transactions') {
              context.push(Routes.transactions);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_transactions',
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, size: 20),
                  const SizedBox(width: 8),
                  Text(isRtl ? 'طلبات التقييم' : 'Rating Requests'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(String error, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref
                .read(chatProvider(widget.conversationId).notifier)
                .loadMessages(),
            child: Text(l10n.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state, int currentUserId) {
    if (state.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.tr('noMessages'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final isMe = message.senderId == currentUserId;

        // Show date separator if needed
        final showDate = index == 0 ||
            !_isSameDay(
              state.messages[index - 1].createdAt,
              message.createdAt,
            );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _buildDateSeparator(message.createdAt),
            MessageBubble(
              message: message,
              isMe: isMe,
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return context.l10n.tr('today');
    }
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return context.l10n.tr('yesterday');
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _onTypingChanged(false);

    final success = await ref
        .read(chatProvider(widget.conversationId).notifier)
        .sendMessage(text);

    if (success) {
      _scrollToBottom();
    }
  }

  void _onTypingChanged(bool typing) {
    if (typing != _isTyping) {
      _isTyping = typing;
      ref.read(chatProvider(widget.conversationId).notifier).sendTyping(typing);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showRatingRequestDialog(BuildContext context, bool isRtl) {
    final chatState = ref.read(chatProvider(widget.conversationId));
    final currentUser = ref.read(currentUserProvider);
    final projectId = chatState.conversation?.projectId;
    final projectOwnerId = chatState.conversation?.project?.userId ??
        chatState.conversation?.project?.owner?.id;

    if (projectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isRtl ? 'خطأ في تحميل المحادثة' : 'Error loading conversation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if user is trying to request rating for their own project
    if (currentUser?.id != null && projectOwnerId == currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRtl
              ? 'لا يمكنك طلب تقييم لمنتجك الخاص'
              : 'You cannot request a rating for your own product'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show product picker bottom sheet
    _showProductPickerSheet(projectId, isRtl);
  }

  void _showProductPickerSheet(int projectId, bool isRtl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProductPickerSheet(
        projectId: projectId,
        isRtl: isRtl,
        onProductSelected: (productId) {
          Navigator.pop(ctx);
          _initiateTransactionWithProduct(productId, isRtl);
        },
        onSkip: () {
          Navigator.pop(ctx);
          // Allow transaction without product (service rating)
          _initiateTransactionWithProduct(null, isRtl);
        },
      ),
    );
  }

  Future<void> _initiateTransactionWithProduct(
      int? productId, bool isRtl) async {
    try {
      final transaction =
          await ref.read(transactionsProvider.notifier).initiateTransaction(
                conversationId: widget.conversationId,
                productId: productId,
              );

      if (mounted) {
        if (transaction != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRtl
                  ? 'تم إرسال طلب التقييم بنجاح'
                  : 'Rating request sent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Get specific error from provider
          final error = ref.read(transactionsProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ??
                  (isRtl ? 'حدث خطأ أثناء الإرسال' : 'Error sending request')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Product picker bottom sheet for rating request
class _ProductPickerSheet extends ConsumerStatefulWidget {
  final int projectId;
  final bool isRtl;
  final Function(int?) onProductSelected;
  final VoidCallback onSkip;

  const _ProductPickerSheet({
    required this.projectId,
    required this.isRtl,
    required this.onProductSelected,
    required this.onSkip,
  });

  @override
  ConsumerState<_ProductPickerSheet> createState() =>
      _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  List<dynamic>? _products;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final repository = ref.read(projectsRepositoryProvider);
      final response = await repository.getProjectProducts(widget.projectId);
      setState(() {
        _products = response.products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.isRtl ? 'اختر المنتج' : 'Select Product',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _products == null || _products!.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  widget.isRtl
                                      ? 'لا توجد منتجات'
                                      : 'No products found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _products!.length,
                            itemBuilder: (context, index) {
                              final product = _products![index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.shopping_bag),
                                ),
                                title: Text(widget.isRtl
                                    ? (product.nameAr ?? product.name)
                                    : product.name),
                                subtitle: Text(
                                    '${product.basePrice.toStringAsFixed(2)} SAR'),
                                onTap: () =>
                                    widget.onProductSelected(product.id),
                              );
                            },
                          ),
          ),
          // Skip button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: widget.onSkip,
                  child: Text(
                    widget.isRtl
                        ? 'تقييم الخدمة بدون منتج'
                        : 'Rate service without product',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
