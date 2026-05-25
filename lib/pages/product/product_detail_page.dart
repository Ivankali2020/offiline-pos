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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: _product.name,
      appBar: CustomAppBar(
        title: _product.name,
        subtitle: 'Product details, attributes, and variants.',
        actions: [
          IconButton(
            tooltip: 'edit'.tr,
            onPressed: () =>
                Get.toNamed(AppRoutes.productForm, arguments: _product),
            icon: const Icon(LucideIcons.pencil),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_product.brandName ?? '-'} • ${_product.categoryName ?? '-'}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Inventory',
                  icon: LucideIcons.package,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoPill(
                        label: 'Stock',
                        value: '${_product.stockQuantity}',
                      ),
                      _InfoPill(
                        label: 'Buy',
                        value:
                            'MMK ${_currencyFormat.format(_product.buyPrice)}',
                      ),
                      _InfoPill(
                        label: 'Sell',
                        value:
                            'MMK ${_currencyFormat.format(_product.sellPrice)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Attributes',
                  icon: LucideIcons.listTree,
                  child: _attributes.isEmpty
                      ? const Text('No attributes selected.')
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
                if (_product.hasVariant) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    title: 'variants'.tr,
                    icon: LucideIcons.boxes,
                    child: _variants.isEmpty
                        ? Text('no_variants'.tr)
                        : Column(
                            children: _variants
                                .map(
                                  (variant) => _VariantTile(
                                    variant: variant,
                                    currencyFormat: _currencyFormat,
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
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
    final color = _parseColor(colorCode ?? '');
    return Chip(
      avatar: color == null
          ? null
          : CircleAvatar(backgroundColor: color, radius: 8),
      label: Text('$label: $value'),
    );
  }
}

class _VariantTile extends StatelessWidget {
  const _VariantTile({required this.variant, required this.currencyFormat});

  final Variant variant;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(variant.name ?? '-'),
      subtitle: Text('Stock: ${variant.stockQuantity}'),
      trailing: Text('MMK ${currencyFormat.format(variant.sellPrice)}'),
    );
  }
}

Color? _parseColor(String rawValue) {
  final value = rawValue.trim().replaceFirst('#', '');
  if (value.length != 6) return null;
  final colorInt = int.tryParse('FF$value', radix: 16);
  return colorInt == null ? null : Color(colorInt);
}
