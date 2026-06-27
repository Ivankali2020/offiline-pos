import 'dart:convert';

import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/data/repositories/variant_repository.dart';
import 'package:abpos/models/product.dart';
import 'package:abpos/models/product_attribute_selection.dart';
import 'package:abpos/models/variant.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Gap extends SizedBox {
  const Gap(double size, {super.key}) : super(width: size, height: size);
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final VariantRepository _variantRepository = VariantRepository();
  late Product _product;
  List<Variant> _variants = [];
  List<ProductAttributeSelection> _attributes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _product = Get.arguments as Product;
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final productId = _product.id;
    if (productId == null) return;

    final controller = Get.find<ProductController>();
    
    // Sync the product instance from the controller's loaded products in case it was edited
    final updatedProduct = controller.products.firstWhereOrNull((p) => p.id == productId);
    if (updatedProduct != null) {
      _product = updatedProduct;
    }

    final results = await Future.wait<dynamic>([
      _variantRepository.findByProductId(productId),
      controller.loadAttributeSelections(productId),
    ]);

    if (!mounted) return;
    setState(() {
      _variants = results[0] as List<Variant>;
      _attributes = results[1] as List<ProductAttributeSelection>;
      _isLoading = false;
    });
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  String _variantAttributeLabel(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! List) return '';

      return decoded
          .whereType<Map>()
          .map((item) {
            final attribute = item['attribute_name']?.toString().trim() ?? '';
            final value = item['value']?.toString().trim() ?? '';
            if (attribute.isEmpty || value.isEmpty) return '';
            return '$attribute: $value';
          })
          .where((label) => label.isNotEmpty)
          .join(', ');
    } catch (_) {
      return '';
    }
  }

  Widget _buildVariantChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return AppScaffold(
        title: _product.name,
        appBar: CustomAppBar(
          title: _product.name,
          subtitle: 'product_details_subtitle'.tr,
        ),
        includeDrawer: false,
        backgroundColor: const Color(0xFFF6F7FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: _product.name,
      appBar: CustomAppBar(
        title: _product.name,
        subtitle: 'product_details_subtitle'.tr,
        actions: [
          IconButton(
            tooltip: 'edit'.tr,
            onPressed: () async {
              await Get.toNamed(AppRoutes.productForm, arguments: _product);
              _loadDetails();
            },
            icon: const Icon(LucideIcons.pencil),
          ),
        ],
      ),
      includeDrawer: false,
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF111827), Color(0xFF1F2937)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _product.hasVariant ? 'variants'.tr : 'product'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Gap(14),
                    Text(
                      _product.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      _product.hasVariant
                          ? 'manage_variants_subtitle'.tr
                          : 'manage_core_info_subtitle'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.4,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(18),
              _buildSectionCard(
                title: 'basic_information'.tr,
                subtitle: 'basic_information_subtitle'.tr,
                child: Column(
                  children: [
                    _ReadOnlyField(
                      label: 'product_name'.tr,
                      value: _product.name,
                    ),
                    const Gap(14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxWidth < 640;
                        final brandField = _ReadOnlyField(
                          label: 'brand_singular'.tr,
                          value: _product.brandName ?? '-',
                        );
                        final categoryField = _ReadOnlyField(
                          label: 'category_singular'.tr,
                          value: _product.categoryName ?? '-',
                        );

                        if (isCompact) {
                          return Column(
                            children: [
                              brandField,
                              const Gap(14),
                              categoryField,
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: brandField),
                            const Gap(14),
                            Expanded(child: categoryField),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (!_product.hasVariant) ...[
                const Gap(16),
                _buildSectionCard(
                  title: 'inventory_pricing'.tr,
                  subtitle: 'inventory_pricing_subtitle'.tr,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ReadOnlyField(
                              label: 'sku_barcode'.tr,
                              value: _product.sku ?? '-',
                              suffixIcon: const Icon(LucideIcons.scanBarcode, size: 18, color: Colors.black45),
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            child: _ReadOnlyField(
                              label: 'stock'.tr,
                              value: '${_product.stockQuantity}',
                              suffixIcon: const Icon(LucideIcons.package, size: 18, color: Colors.black45),
                            ),
                          ),
                        ],
                      ),
                      const Gap(14),
                      Row(
                        children: [
                          Expanded(
                            child: _ReadOnlyField(
                              label: 'buy_price'.tr,
                              value: 'MMK ${_currencyFormat.format(_product.buyPrice)}',
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            child: _ReadOnlyField(
                              label: 'sell_price'.tr,
                              value: 'MMK ${_currencyFormat.format(_product.sellPrice)}',
                            ),
                          ),
                        ],
                      ),
                      if (_product.expiredDate != null &&
                          _product.expiredDate!.trim().isNotEmpty) ...[
                        const Gap(14),
                        _ReadOnlyField(
                          label: 'expired_date'.tr,
                          value: _product.expiredDate!,
                          suffixIcon: const Icon(LucideIcons.calendarClock, size: 18, color: Colors.black45),
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(16),
                _buildSectionCard(
                  title: 'attributes'.tr,
                  subtitle: 'attributes_subtitle'.tr,
                  child: _attributes.isEmpty
                      ? Text(
                          'no_attributes_selected_yet'.tr,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _attributes
                              .map(
                                (item) => _AttributePill(
                                  label: item.attributeName ?? '-',
                                  value: item.value ?? '-',
                                  colorCode: item.colorCode,
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
              if (_product.hasVariant) ...[
                const Gap(16),
                _buildSectionCard(
                  title: 'variants'.tr,
                  subtitle: 'variants_subtitle'.tr,
                  child: _variants.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                LucideIcons.boxes,
                                size: 28,
                                color: Colors.black45,
                              ),
                              const Gap(10),
                              Text(
                                'no_variants'.tr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: _variants.asMap().entries.map((entry) {
                            final index = entry.key;
                            final v = entry.value;
                            final attributeLabel = _variantAttributeLabel(
                              v.attributes,
                            );
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == _variants.length - 1 ? 0 : 12,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.name ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (attributeLabel.isNotEmpty) ...[
                                      const Gap(2),
                                      Text(
                                        attributeLabel,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    const Gap(10),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _buildVariantChip(
                                          LucideIcons.scanBarcode,
                                          (v.sku == null || v.sku!.isEmpty)
                                              ? 'No SKU'
                                              : v.sku!,
                                        ),
                                        _buildVariantChip(
                                          LucideIcons.package,
                                          '${'qty'.tr}: ${v.stockQuantity}',
                                        ),
                                        _buildVariantChip(
                                          LucideIcons.badgeDollarSign,
                                          '${'price'.tr}: ${v.sellPrice.toStringAsFixed(0)}',
                                        ),
                                        if (v.expiredDate != null &&
                                            v.expiredDate!.isNotEmpty)
                                          _buildVariantChip(
                                            LucideIcons.calendarClock,
                                            '${'expired_date'.tr}: ${v.expiredDate}',
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.suffixIcon,
  });

  final String label;
  final String value;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                const SizedBox(width: 8),
                suffixIcon!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AttributePill extends StatelessWidget {
  const _AttributePill({
    required this.label,
    required this.value,
    this.colorCode,
  });

  final String label;
  final String value;
  final String? colorCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(colorCode ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12, width: 0.5),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            '$label: $value',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

Color? _parseColor(String rawValue) {
  final value = rawValue.trim().replaceFirst('#', '');
  if (value.length != 6) return null;
  final colorInt = int.tryParse('FF$value', radix: 16);
  return colorInt == null ? null : Color(colorInt);
}
