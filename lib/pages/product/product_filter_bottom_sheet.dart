import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/controllers/brand_controller.dart';
import 'package:abpos/controllers/category_controller.dart';
import 'package:abpos/widgets/app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductFilterBottomSheet extends StatefulWidget {
  const ProductFilterBottomSheet({super.key, required this.controller});

  final ProductController controller;

  static Future<void> show(BuildContext context, ProductController controller) {
    return AppBottomSheet.show<void>(
      context,
      title: 'filter_products'.tr,
      subtitle: 'filter_products_subtitle'.tr,
      trailing: TextButton(
        onPressed: () {
          controller.resetFilters();
          Get.back<void>();
        },
        child: Text('reset'.tr),
      ),
      child: ProductFilterBottomSheet(controller: controller),
    );
  }

  @override
  State<ProductFilterBottomSheet> createState() => _ProductFilterBottomSheetState();
}

class _ProductFilterBottomSheetState extends State<ProductFilterBottomSheet> {
  late int? _selectedBrandId;
  late int? _selectedCategoryId;
  late bool _showEmptyStockOnly;

  @override
  void initState() {
    super.initState();
    _selectedBrandId = widget.controller.selectedBrandId.value;
    _selectedCategoryId = widget.controller.selectedCategoryId.value;
    _showEmptyStockOnly = widget.controller.showEmptyStockOnly.value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brandController = Get.find<BrandController>();
    final categoryController = Get.find<CategoryController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'brand_singular'.tr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          initialValue: _selectedBrandId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('all_brands'.tr),
            ),
            ...brandController.brands.map(
              (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _selectedBrandId = val;
            });
          },
        ),
        const SizedBox(height: 24),
        Text(
          'category_singular'.tr,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('all_categories'.tr),
            ),
            ...categoryController.categories.map(
              (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _selectedCategoryId = val;
            });
          },
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          title: Text(
            'out_of_stock_only'.tr,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          value: _showEmptyStockOnly,
          onChanged: (val) {
            setState(() {
              _showEmptyStockOnly = val;
            });
          },
          contentPadding: EdgeInsets.zero,
          activeThumbColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back<void>(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('cancel'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.controller.selectedBrandId.value = _selectedBrandId;
                  widget.controller.selectedCategoryId.value = _selectedCategoryId;
                  widget.controller.showEmptyStockOnly.value = _showEmptyStockOnly;
                  Get.back<void>();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('apply_filters'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
