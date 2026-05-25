import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/controllers/purchase_cart_controller.dart';
import 'package:abpos/models/product.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/barcode_scanner_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PurchaseProductPickerPage extends StatefulWidget {
  const PurchaseProductPickerPage({super.key});

  @override
  State<PurchaseProductPickerPage> createState() =>
      _PurchaseProductPickerPageState();
}

class _PurchaseProductPickerPageState extends State<PurchaseProductPickerPage> {
  final ProductController controller = Get.find<ProductController>();
  final PurchaseCartController cartController =
      Get.find<PurchaseCartController>();
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
    final crossAxisCount = screenWidth < 600 ? 2 : (screenWidth < 900 ? 3 : 4);

    return AppScaffold(
      title: 'Pick Purchase Products',
      appBar: CustomAppBar(
        title: 'Pick Purchase Products',
        subtitle: 'Search and scan products to add to purchase receipt.',
        actions: [
          BarcodeScannerButton(
            onScan: (code) {
              setState(() {
                _searchController.text = code;
              });
              controller.searchQuery.value = code;
              Get.snackbar(
                'Scanned',
                code,
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.10),
                ),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search products',
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
                        child: _MiniStat(
                          title: 'Results',
                          value: '${controller.filteredProducts.length}',
                          icon: Icons.grid_view_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(
                          () => _MiniStat(
                            title: 'Picked Qty',
                            value: '${cartController.totalQuantity}',
                            icon: Icons.inventory_2_outlined,
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
                return const Center(child: Text('No products found'));
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: screenWidth < 600 ? 1.1 : 1.38,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _PickerCard(
                    product: product,
                    onTap: () => _showAddProductSheet(product),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAddProductSheet(Product product) {
    final quantityController = TextEditingController(text: '1');
    final costController = TextEditingController(
      text: product.buyPrice.toStringAsFixed(
        product.buyPrice.truncateToDouble() == product.buyPrice ? 0 : 2,
      ),
    );
    final sellController = TextEditingController(
      text: product.sellPrice.toStringAsFixed(
        product.sellPrice.truncateToDouble() == product.sellPrice ? 0 : 2,
      ),
    );

    Get.bottomSheet(
      isScrollControlled: true,
      _AddProductSheet(
        product: product,
        quantityController: quantityController,
        costController: costController,
        sellController: sellController,
        onSave: () {
          final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
          final costPrice = double.tryParse(costController.text.trim());
          final sellPrice = double.tryParse(sellController.text.trim());

          if (quantity <= 0 || costPrice == null || costPrice < 0) {
            Get.snackbar(
              'Missing details',
              'Enter a valid quantity and cost price.',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          cartController.addProduct(
            product,
            quantity: quantity,
            costPrice: costPrice,
            sellPrice: sellPrice ?? product.sellPrice,
          );
          Get.back();
          Get.snackbar(
            'Added',
            '${product.name} added to purchase',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 1),
          );
        },
      ),
    );
  }
}

class _AddProductSheet extends StatelessWidget {
  const _AddProductSheet({
    required this.product,
    required this.quantityController,
    required this.costController,
    required this.sellController,
    required this.onSave,
  });

  final Product product;
  final TextEditingController quantityController;
  final TextEditingController costController;
  final TextEditingController sellController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  product.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Set the purchase details before adding this product.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Cost Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: sellController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Sell Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSave,
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
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

class _PickerCard extends StatelessWidget {
  const _PickerCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Stock ${product.stockQuantity}',
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
              Text(
                'Buy MMK ${product.buyPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Color(0xFF0F766E),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.plusCircle, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
