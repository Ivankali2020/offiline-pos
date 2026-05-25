import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/controllers/cart_controller.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/form/barcode_scanner_button.dart';
import 'package:abpos/models/product.dart';

class ProductPickerPage extends StatefulWidget {
  const ProductPickerPage({super.key});

  @override
  State<ProductPickerPage> createState() => _ProductPickerPageState();
}

class _ProductPickerPageState extends State<ProductPickerPage> {
  final ProductController controller = Get.find<ProductController>();
  final CartController cartController = Get.find<CartController>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = controller.searchQuery.value;
    _searchController.addListener(() {
      controller.searchQuery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth < 600
        ? 2
        : (screenWidth < 900 ? 3 : 4);

    return AppScaffold(
      title: 'select_products'.tr,
      includeDrawer: false,
      // backgroundColor: pageBackground,
      actions: [
        BarcodeScannerButton(
          onScan: (code) {
            setState(() {
              _searchController.text = code;
            });
            Get.snackbar('scanned'.tr, code);
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'search_products'.tr,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      prefixIcon: const Icon(LucideIcons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(LucideIcons.xCircle),
                        onPressed: _searchController.clear,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerMiniStat(
                          title: 'Results',
                          value: '${controller.filteredProducts.length}',
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(
                          () => _PickerMiniStat(
                            title: 'Cart Items',
                            value: '${cartController.totalQuantity}',
                            icon: Icons.shopping_bag_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final products = controller.filteredProducts;
              if (products.isEmpty) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('no_products'.tr),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: screenWidth < 600 ? 1.2 : 1.38,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _PickerProductCard(
                    product: product,
                    onTap: () {
                      cartController.addProduct(product);
                      Get.snackbar(
                        'success'.tr,
                        '${product.name} ${'added_to_cart'.tr}',
                        snackPosition: SnackPosition.BOTTOM,
                        duration: const Duration(seconds: 1),
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PickerProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _PickerProductCard({required this.product, required this.onTap});

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
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
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
              SizedBox(
                width: double.infinity,
                child: Container(
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
                        LucideIcons.plusCircle,
                        size: 15,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Add',
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

class _PickerMiniStat extends StatelessWidget {
  const _PickerMiniStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
