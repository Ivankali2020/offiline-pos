import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/pages/product/product_filter_bottom_sheet.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/models/product.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductController>();

    final theme = Theme.of(context);
    // Responsive columns: 2 on mobile, 3 on small tablets, 4 on larger screens
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth < 900 ? 3 : 4);

    return AppScaffold(
      title: 'products'.tr,
      appBar: CustomAppBar(
        title: 'products'.tr,
        subtitle: 'Manage inventory and product filters',
        leadingIcon: LucideIcons.menu,
        iconColor: theme.colorScheme.primary,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_products'.tr,
                onChanged: (value) => controller.searchQuery.value = value,
                onClear: () {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                },
              )
            : null,
        actions: [
          IconButton(
            color: theme.colorScheme.primary,
            icon: Icon(_showSearch ? LucideIcons.x : LucideIcons.search),
            onPressed: () {
              setState(() {
                if (_showSearch) {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                }
                _showSearch = !_showSearch;
              });
            },
          ),
          Obx(() {
            int activeCount = 0;
            if (controller.selectedBrandId.value != null) activeCount++;
            if (controller.selectedCategoryId.value != null) activeCount++;
            if (controller.showEmptyStockOnly.value) activeCount++;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Filter products',
                    color: theme.colorScheme.primary,
                    onPressed: () =>
                        ProductFilterBottomSheet.show(context, controller),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                  if (activeCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$activeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.productForm),
        child: const Icon(LucideIcons.plus),
      ),
      body: Column(
        children: [
          Obx(() {
            int activeCount = 0;
            if (controller.selectedBrandId.value != null) activeCount++;
            if (controller.selectedCategoryId.value != null) activeCount++;
            if (controller.showEmptyStockOnly.value) activeCount++;

            if (activeCount > 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ActiveFilterBar(controller: controller),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              final products = controller.filteredProducts;
              if (products.isEmpty) {
                return Center(child: Text('no_products'.tr));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: screenWidth < 600 ? 1.1 : 1.38,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _ProductCard(
                    product: product,
                    onTap: () => Get.toNamed(
                      AppRoutes.productDetail,
                      arguments: product,
                    ),
                    onEdit: () =>
                        Get.toNamed(AppRoutes.productForm, arguments: product),
                    onDelete: () =>
                        _confirmDelete(context, controller, product),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProductController controller,
    Product product,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('delete'.tr),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () {
              if (product.id != null) {
                controller.deleteProduct(product.id!);
              }
              Get.back();
            },
            child: Text('delete'.tr, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        cursorColor: Colors.black,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(LucideIcons.search, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          suffixIcon: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.black54),
            onPressed: onClear,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.controller});

  final ProductController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Active Filters',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: controller.resetFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (controller.selectedBrandId.value != null)
                _FilterChip(
                  label: 'brand_id'.trParams({
                    'id': controller.selectedBrandId.value.toString(),
                  }),
                ),
              if (controller.selectedCategoryId.value != null)
                _FilterChip(
                  label: 'category_id'.trParams({
                    'id': controller.selectedCategoryId.value.toString(),
                  }),
                ),
              if (controller.showEmptyStockOnly.value)
                _FilterChip(label: 'out_of_stock'.tr),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStockBadge(context),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.brandName ?? '-'} • ${product.categoryName ?? '-'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
              ),
              const Spacer(),
              if (!product.hasVariant)
                Text(
                  'MMK ${product.sellPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'variants'.tr,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.pencil,
                              size: 15,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: onDelete,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 15,
                              color: Colors.red,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(BuildContext context) {
    final bool isLow = product.stockQuantity <= product.stockThreshold;
    final Color color = isLow ? Colors.red : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Stock: ${product.stockQuantity}',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
