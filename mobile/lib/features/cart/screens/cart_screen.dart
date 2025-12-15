import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../config/routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/providers/cart_provider.dart';
import 'cart_item_card.dart';

/// Cart Screen - displays inquiry cart items grouped by project
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final isRtl = context.isRtl;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.tr('inquiryCart')),
        actions: [
          if (!cartState.isEmpty)
            TextButton(
              onPressed: () => _showClearCartDialog(context),
              child: Text(
                l10n.tr('clearAll'),
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
      body: _buildBody(cartState, isRtl, l10n),
      bottomNavigationBar:
          cartState.isEmpty ? null : _buildSendButton(cartState, l10n),
    );
  }

  Widget _buildBody(CartState cartState, bool isRtl, AppLocalizations l10n) {
    if (cartState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cartState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(cartState.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(cartProvider.notifier).loadCart(),
              child: Text(l10n.tr('retry')),
            ),
          ],
        ),
      );
    }

    if (cartState.isEmpty) {
      return _buildEmptyState(l10n);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(cartProvider.notifier).loadCart(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: cartState.groups.length,
        itemBuilder: (context, index) {
          return _buildProjectGroup(cartState.groups[index], isRtl, l10n);
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withAlpha(100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 80,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tr('emptyCart'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tr('addProductsToCart'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(Routes.home),
              icon: const Icon(Icons.explore),
              label: Text(l10n.tr('browseProducts')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectGroup(
      CartGroup group, bool isRtl, AppLocalizations l10n) {
    final project = group.project;
    final projectName = isRtl ? project.nameAr : project.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project header
          InkWell(
            onTap: () {
              context.push(
                Routes.projectDetail
                    .replaceFirst(':projectId', project.id.toString()),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(10),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: project.logoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: ApiEndpoints.imageUrl(project.logoUrl),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.store,
                            color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          projectName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              project.city,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${group.items.length} ${l10n.tr('productsCount')}',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // Cart items
          ...group.items.map((item) => CartItemCard(
                item: item,
                onQuantityChanged: (newQuantity) {
                  ref.read(cartProvider.notifier).updateCartItem(
                        itemId: item.id,
                        quantity: newQuantity,
                      );
                },
                onRemove: () {
                  ref.read(cartProvider.notifier).removeFromCart(item.id);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSendButton(CartState cartState, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tr('projects'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '${cartState.projectCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tr('totalProducts'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                Text(
                  '${cartState.totalItems}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: cartState.isSending
                    ? null
                    : () => _showSendConfirmation(l10n),
                icon: cartState.isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  cartState.isSending
                      ? l10n.tr('sending')
                      : l10n.tr('sendInquiries'),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.tr('clearCart')),
        content: Text(l10n.tr('clearCartConfirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cartProvider.notifier).clearCart();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.tr('clearAll')),
          ),
        ],
      ),
    );
  }

  void _showSendConfirmation(AppLocalizations l10n) {
    final cartState = ref.read(cartProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tr('sendInquiries')),
        content: Text(
          l10n
              .tr('sendInquiriesConfirmation')
              .replaceAll('{count}', cartState.projectCount.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final response =
                  await ref.read(cartProvider.notifier).sendInquiries();
              if (response != null && mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.tr('inquiriesSent')),
                    backgroundColor: AppColors.success,
                  ),
                );
                // Navigate to conversations
                if (response.conversationIds.isNotEmpty) {
                  navigator.go(Routes.conversations);
                }
              }
            },
            child: Text(l10n.tr('send')),
          ),
        ],
      ),
    );
  }
}
