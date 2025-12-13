import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ProductsListScreen extends StatelessWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إدارة المنتجات',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // Status tabs
          DefaultTabController(
            length: 3,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    labelColor: AdminColors.primary,
                    unselectedLabelColor: AdminColors.textSecondary,
                    indicatorColor: AdminColors.primary,
                    tabs: const [
                      Tab(text: 'الكل'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('في الانتظار'),
                            SizedBox(width: 8),
                            Badge(
                              backgroundColor: AdminColors.warning,
                              label: Text('5'),
                            ),
                          ],
                        ),
                      ),
                      Tab(text: 'المعتمدة'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildProductsGrid(context),
                        _buildProductsGrid(context),
                        _buildProductsGrid(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildProductCard(context, index);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, int index) {
    final status = index % 3;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            flex: 3,
            child: Container(
              color: AdminColors.surfaceVariant,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Center(
                    child: Icon(Icons.image, size: 48, color: AdminColors.textTertiary),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusBadge(status),
                  ),
                ],
              ),
            ),
          ),
          
          // Product info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'منتج ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مشروع ${(index % 5) + 1}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(index + 1) * 25} ر.س',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AdminColors.primary,
                        ),
                      ),
                      Row(
                        children: [
                          if (status == 0) ...[
                            IconButton(
                              icon: const Icon(Icons.check, color: AdminColors.success, size: 20),
                              onPressed: () {},
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AdminColors.error, size: 20),
                              onPressed: () {},
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                            ),
                          ],
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20),
                            onPressed: () {},
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int status) {
    final statuses = ['قيد المراجعة', 'معتمد', 'مرفوض'];
    final bgColors = [AdminColors.pendingBg, AdminColors.approvedBg, AdminColors.rejectedBg];
    final textColors = [AdminColors.pendingText, AdminColors.approvedText, AdminColors.rejectedText];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColors[status],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statuses[status],
        style: TextStyle(
          color: textColors[status],
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

