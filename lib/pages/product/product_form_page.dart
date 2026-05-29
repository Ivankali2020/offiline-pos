import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/controllers/brand_controller.dart';
import 'package:abpos/controllers/category_controller.dart';
import 'package:abpos/controllers/attribute_controller.dart';
import 'package:abpos/data/repositories/variant_repository.dart';
import 'package:abpos/models/attribute.dart';
import 'package:abpos/models/attribute_value.dart';
import 'package:abpos/models/product.dart';
import 'package:abpos/models/product_attribute_selection.dart';
import 'package:abpos/models/variant.dart';
import 'package:abpos/models/brand.dart';
import 'package:abpos/models/category.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/custom_dropdown_field.dart';
import 'package:abpos/widgets/form/custom_nav_selector.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:abpos/widgets/form/barcode_scanner_button.dart';

import 'package:abpos/widgets/app_bottom_action_bar.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';

class Gap extends SizedBox {
  const Gap(double size, {super.key}) : super(width: size, height: size);
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductAttributeDraft {
  const _ProductAttributeDraft({
    this.attribute,
    this.value,
    this.values = const [],
  });

  final Attribute? attribute;
  final AttributeValue? value;
  final List<AttributeValue> values;

  _ProductAttributeDraft copyWith({
    Attribute? attribute,
    AttributeValue? value,
    List<AttributeValue>? values,
  }) {
    return _ProductAttributeDraft(
      attribute: attribute ?? this.attribute,
      value: value ?? this.value,
      values: values ?? this.values,
    );
  }

  Map<String, Object?> toPayload() {
    return {
      'attribute_id': attribute?.id,
      'attribute_name': attribute?.name,
      'attribute_type': attribute?.type,
      'value_id': value?.id,
      'value': value?.value,
      'color_code': value?.colorCode,
    };
  }

  String get displayLabel {
    final attributeName = attribute?.name.trim() ?? '';
    final valueName = value?.value.trim() ?? '';
    if (attributeName.isEmpty || valueName.isEmpty) return '';
    return '$attributeName: $valueName';
  }
}

class _ProductAttributeSelector extends StatelessWidget {
  const _ProductAttributeSelector({
    super.key,
    required this.attributes,
    required this.draft,
    required this.onAttributeChanged,
    required this.onValueChanged,
    required this.onRemove,
  });

  final List<Attribute> attributes;
  final _ProductAttributeDraft draft;
  final ValueChanged<Attribute?> onAttributeChanged;
  final ValueChanged<AttributeValue?> onValueChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomDropdownField<int>(
                  value: draft.attribute?.id,
                  label: 'attributes'.tr,
                  items: attributes
                      .map(
                        (attribute) => DropdownMenuItem<int>(
                          value: attribute.id,
                          child: Text(attribute.name),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    final attribute = attributes.firstWhereOrNull(
                      (item) => item.id == id,
                    );
                    onAttributeChanged(attribute);
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(LucideIcons.trash2, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomDropdownField<int>(
            value: draft.value?.id,
            label: 'attribute_value'.tr,
            items: draft.values
                .map(
                  (value) => DropdownMenuItem<int>(
                    value: value.id,
                    child: Row(
                      children: [
                        if ((value.colorCode ?? '').trim().isNotEmpty) ...[
                          _AttributeColorDot(colorCode: value.colorCode!),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          value.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: draft.attribute == null
                ? null
                : (id) {
                    final value = draft.values.firstWhereOrNull(
                      (item) => item.id == id,
                    );
                    onValueChanged(value);
                  },
          ),
          if (draft.attribute != null && draft.values.isEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'no_values_for_attribute'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantAttributeEditor extends StatelessWidget {
  const _VariantAttributeEditor({
    required this.drafts,
    required this.onAdd,
    required this.onRemove,
    required this.onAttributeChanged,
    required this.onValueChanged,
  });

  final List<_ProductAttributeDraft> drafts;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, Attribute? attribute) onAttributeChanged;
  final void Function(int index, AttributeValue? value) onValueChanged;

  @override
  Widget build(BuildContext context) {
    final attributes = Get.find<AttributeController>().attributes.toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'attributes'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: Text('add'.tr),
              ),
            ],
          ),
          if (drafts.isEmpty)
            Text(
              'no_attributes_selected_yet'.tr,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            )
          else
            Column(
              children: drafts.asMap().entries.map((entry) {
                final index = entry.key;
                final draft = entry.value;
                return Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 4 : 10),
                  child: _ProductAttributeSelector(
                    key: ValueKey(
                      'variant-attribute-$index-${draft.attribute?.id}',
                    ),
                    attributes: attributes,
                    draft: draft,
                    onAttributeChanged: (attribute) =>
                        onAttributeChanged(index, attribute),
                    onValueChanged: (value) => onValueChanged(index, value),
                    onRemove: () => onRemove(index),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _AttributeColorDot extends StatelessWidget {
  const _AttributeColorDot({required this.colorCode});

  final String colorCode;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorCode);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).dividerColor),
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

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Track if we are in Edit Mode
  Product? _editingProduct;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _sellPriceController = TextEditingController();
  final TextEditingController _buyPriceController = TextEditingController();
  final TextEditingController _stockQuantityController = TextEditingController(
    text: '0',
  );

  final RxList<Variant> _variants = <Variant>[].obs;
  final List<_ProductAttributeDraft> _attributeDrafts = [];
  bool _hasVariant = false;

  Brand? _selectedBrand;
  Category? _selectedCategory;

  final _variantRepository = VariantRepository();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _editingProduct = Get.arguments as Product?;
    await _ensureAttributeChoices();
    if (_editingProduct != null) {
      await _populateFields();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _ensureAttributeChoices() async {
    final attributeController = Get.find<AttributeController>();
    if (attributeController.attributes.isEmpty) {
      await attributeController.loadAttributes();
    }
  }

  Future<void> _populateFields() async {
    final p = _editingProduct!;

    // Set text controllers
    _nameController.text = p.name;
    _skuController.text = p.sku ?? '';
    _sellPriceController.text = p.sellPrice.toStringAsFixed(0);
    _buyPriceController.text = p.buyPrice.toStringAsFixed(0);
    _stockQuantityController.text = p.stockQuantity.toString();

    if (!mounted) return;
    setState(() {
      _hasVariant = p.hasVariant;

      // Initialize brand/category from joined data if available
      if (p.brandId != null) {
        _selectedBrand = Brand(
          id: p.brandId,
          sellerId: p.sellerId,
          name: p.brandName ?? '...',
        );
      }
      if (p.categoryId != null) {
        _selectedCategory = Category(
          id: p.categoryId,
          sellerId: p.sellerId,
          name: p.categoryName ?? '...',
          isSubCategory: false,
        );
      }
    });

    // Load variants from DB
    if (_hasVariant) {
      final loadedVariants = await _variantRepository.findByProductId(p.id!);
      if (!mounted) return;
      _variants.assignAll(loadedVariants);
    }

    final controller = Get.find<ProductController>();
    final attributeController = Get.find<AttributeController>();
    final selections = await controller.loadAttributeSelections(p.id!);
    final drafts = <_ProductAttributeDraft>[];
    for (final selection in selections) {
      final attribute = attributeController.attributes.firstWhereOrNull(
        (item) => item.id == selection.attributeId,
      );
      if (attribute == null) continue;
      final values = await attributeController.loadValuesForAttribute(
        attribute.id!,
      );
      final value = values.firstWhereOrNull(
        (item) => item.id == selection.attributeValueId,
      );
      drafts.add(
        _ProductAttributeDraft(
          attribute: attribute,
          value: value,
          values: values,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _attributeDrafts
          ..clear()
          ..addAll(drafts);
      });
    }

    // Try to sync with full objects from controllers once they are ready
    await _syncMetadata();
  }

  Future<void> _syncMetadata() async {
    final p = _editingProduct!;
    final brandController = Get.find<BrandController>();
    final categoryController = Get.find<CategoryController>();

    // If lists are empty, they might still be loading
    if (brandController.brands.isEmpty) await brandController.loadBrands();
    if (categoryController.categories.isEmpty) {
      await categoryController.loadCategories();
    }

    if (!mounted) return;
    setState(() {
      if (p.brandId != null) {
        _selectedBrand =
            brandController.brands.firstWhereOrNull((b) => b.id == p.brandId) ??
            _selectedBrand;
      }
      if (p.categoryId != null) {
        _selectedCategory =
            categoryController.categories.firstWhereOrNull(
              (c) => c.id == p.categoryId,
            ) ??
            _selectedCategory;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _sellPriceController.dispose();
    _buyPriceController.dispose();
    _stockQuantityController.dispose();
    super.dispose();
  }

  // --- Field Configurations for Looping ---

  String? _requiredTextValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'required_field'.tr;
    return null;
  }

  String? _requiredNumberValidator(String? value) {
    final rawValue = value?.trim() ?? '';
    if (rawValue.isEmpty) return 'required_field'.tr;
    final number = double.tryParse(rawValue);
    if (number == null || number < 0) return 'Enter a valid number.';
    return null;
  }

  String? _requiredIntegerValidator(String? value) {
    final rawValue = value?.trim() ?? '';
    if (rawValue.isEmpty) return 'required_field'.tr;
    final number = int.tryParse(rawValue);
    if (number == null || number < 0) return 'Enter a valid quantity.';
    return null;
  }

  List<Widget> _buildInventoryFields() {
    if (_hasVariant) return [];

    return [
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _skuController,
              label: 'sku_barcode'.tr,
              isRequired: true,
              validator: _requiredTextValidator,
              suffixIcon: BarcodeScannerButton(
                onScan: (code) => setState(() => _skuController.text = code),
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: CustomTextField(
              controller: _stockQuantityController,
              label: 'initial_stock'.tr,
              isRequired: true,
              keyboardType: TextInputType.number,
              validator: _requiredIntegerValidator,
            ),
          ),
        ],
      ),
      const Gap(24),
      Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _buyPriceController,
              label: 'buy_price'.tr,
              isRequired: true,
              keyboardType: TextInputType.number,
              validator: _requiredNumberValidator,
            ),
          ),
          const Gap(16),
          Expanded(
            child: CustomTextField(
              controller: _sellPriceController,
              label: 'sell_price'.tr,
              isRequired: true,
              keyboardType: TextInputType.number,
              validator: _requiredNumberValidator,
            ),
          ),
        ],
      ),
      const Gap(24),
    ];
  }

  void _showVariantDialog({Variant? variant, int? index}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: variant?.name);
    final skuCtrl = TextEditingController(text: variant?.sku);
    final stockCtrl = TextEditingController(
      text: variant?.stockQuantity.toString() ?? '0',
    );
    final sellPriceCtrl = TextEditingController(
      text: variant?.sellPrice.toStringAsFixed(0) ?? '0',
    );
    final buyPriceCtrl = TextEditingController(
      text: variant?.buyPrice.toStringAsFixed(0) ?? '0',
    );
    final attributeDrafts = <_ProductAttributeDraft>[];
    var isLoadingAttributes = variant?.attributes?.trim().isNotEmpty == true;

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> selectVariantAttribute(
            int draftIndex,
            Attribute? attribute,
          ) async {
            if (attribute == null || attribute.id == null) return;
            final values = await Get.find<AttributeController>()
                .loadValuesForAttribute(attribute.id!);
            setSheetState(() {
              attributeDrafts[draftIndex] = _ProductAttributeDraft(
                attribute: attribute,
                value: null,
                values: values,
              );
            });
          }

          if (isLoadingAttributes) {
            isLoadingAttributes = false;
            _decodeAttributeDrafts(variant?.attributes).then((drafts) {
              if (context.mounted) {
                setSheetState(() => attributeDrafts.addAll(drafts));
              }
            });
          }

          return CustomFormSheet(
            title: variant == null ? 'add_variant'.tr : 'edit'.tr,
            subtitle: 'set_compact_variant_details'.tr,
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nameCtrl,
                    label: 'name'.tr,
                    isRequired: true,
                    validator: _requiredTextValidator,
                  ),
                  const Gap(14),
                  _VariantAttributeEditor(
                    drafts: attributeDrafts,
                    onAdd: () => setSheetState(
                      () => attributeDrafts.add(_ProductAttributeDraft()),
                    ),
                    onRemove: (draftIndex) => setSheetState(
                      () => attributeDrafts.removeAt(draftIndex),
                    ),
                    onAttributeChanged: selectVariantAttribute,
                    onValueChanged: (draftIndex, value) {
                      setSheetState(() {
                        attributeDrafts[draftIndex] =
                            attributeDrafts[draftIndex].copyWith(
                              value: value,
                            );
                      });
                    },
                  ),
                  const Gap(14),
                  CustomTextField(
                    controller: skuCtrl,
                    label: 'sku_barcode'.tr,
                    isRequired: true,
                    validator: _requiredTextValidator,
                    suffixIcon: BarcodeScannerButton(
                      onScan: (code) => skuCtrl.text = code,
                    ),
                  ),
                  const Gap(14),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: stockCtrl,
                          label: 'qty'.tr,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          validator: _requiredIntegerValidator,
                        ),
                      ),
                      const Gap(14),
                      Expanded(
                        child: CustomTextField(
                          controller: buyPriceCtrl,
                          label: 'buy_price'.tr,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          validator: _requiredNumberValidator,
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  CustomTextField(
                    controller: sellPriceCtrl,
                    label: 'sell_price'.tr,
                    isRequired: true,
                    keyboardType: TextInputType.number,
                    validator: _requiredNumberValidator,
                  ),
                  const Gap(20),
                  FormActionButtons(
                    confirmLabel: variant == null ? 'add'.tr : 'save'.tr,
                    onConfirm: () {
                      if (!formKey.currentState!.validate()) return;

                      final updatedVariant = Variant(
                        id: variant?.id,
                        productId: variant?.productId ?? 0,
                        name: nameCtrl.text.trim(),
                        attributes: _encodeAttributeDrafts(
                          attributeDrafts,
                        ),
                        sku: skuCtrl.text.trim(),
                        stockQuantity:
                            int.tryParse(stockCtrl.text) ?? 0,
                        sellPrice:
                            double.tryParse(sellPriceCtrl.text) ??
                            0,
                        buyPrice:
                            double.tryParse(buyPriceCtrl.text) ?? 0,
                      );

                      if (index != null) {
                        _variants[index] = updatedVariant;
                      } else {
                        _variants.add(updatedVariant);
                      }
                      Get.back();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProduct() async {
    final FormState? formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    if (_hasVariant && _variants.isEmpty) {
      Get.snackbar('error'.tr, 'missing_variants_error'.tr);
      return;
    }

    final controller = Get.find<ProductController>();

    final product = Product(
      id: _editingProduct?.id, // Preserve ID for update
      sellerId: 1,
      categoryId: _selectedCategory?.id,
      brandId: _selectedBrand?.id,
      supplierId: null,
      sku: _hasVariant
          ? null
          : (_skuController.text.trim().isEmpty
                ? null
                : _skuController.text.trim()),
      name: _nameController.text.trim(),
      description: null,
      stockQuantity: _hasVariant
          ? 0
          : (int.tryParse(_stockQuantityController.text) ?? 0),
      stockThreshold: 0,
      sellPrice: _hasVariant
          ? 0
          : (double.tryParse(_sellPriceController.text) ?? 0),
      buyPrice: _hasVariant
          ? 0
          : (double.tryParse(_buyPriceController.text) ?? 0),
      hasVariant: _hasVariant,
      isActive: true,
    );

    try {
      if (_editingProduct == null) {
        // Create Mode
        final productId = await controller.insertProduct(product);
        if (_hasVariant) {
          for (final variant in _variants) {
            await _variantRepository.insert(
              Variant(
                productId: productId,
                name: variant.name,
                attributes: variant.attributes,
                sku: variant.sku,
                stockQuantity: variant.stockQuantity,
                sellPrice: variant.sellPrice,
                buyPrice: variant.buyPrice,
              ),
            );
          }
        }
        await controller.saveAttributeSelections(
          productId,
          _hasVariant ? [] : _buildAttributeSelections(productId),
        );
      } else {
        // Edit Mode
        await controller.updateProduct(product);

        // Sync variants: Simple strategy: delete old and insert new
        // A more advanced strategy would be ID matching, but this works for local DB
        final existingVariants = await _variantRepository.findByProductId(
          product.id!,
        );
        for (var v in existingVariants) {
          await _variantRepository.delete(v.id!);
        }

        if (_hasVariant) {
          for (final variant in _variants) {
            await _variantRepository.insert(
              Variant(
                productId: product.id!,
                name: variant.name,
                attributes: variant.attributes,
                sku: variant.sku,
                stockQuantity: variant.stockQuantity,
                sellPrice: variant.sellPrice,
                buyPrice: variant.buyPrice,
              ),
            );
          }
        }
        await controller.saveAttributeSelections(
          product.id!,
          _hasVariant ? [] : _buildAttributeSelections(product.id!),
        );
      }

      await controller.loadProducts();
      if (mounted) {
        Get.back();
        Get.snackbar('success'.tr, 'saved_successfully'.tr);
      }
    } catch (e, stack) {
      debugPrint('Save Error: $e');
      debugPrint('Stack Trace: $stack');
      Get.snackbar('error'.tr, 'Failed to save: $e');
    }
  }

  void _addAttributeDraft() {
    setState(() => _attributeDrafts.add(_ProductAttributeDraft()));
  }

  void _removeAttributeDraft(int index) {
    setState(() => _attributeDrafts.removeAt(index));
  }

  Future<void> _selectAttribute(int index, Attribute? attribute) async {
    if (attribute == null || attribute.id == null) return;
    final values = await Get.find<AttributeController>().loadValuesForAttribute(
      attribute.id!,
    );
    if (!mounted) return;
    setState(() {
      _attributeDrafts[index] = _ProductAttributeDraft(
        attribute: attribute,
        value: null,
        values: values,
      );
    });
  }

  List<ProductAttributeSelection> _buildAttributeSelections(int productId) {
    final seen = <String>{};
    final selections = <ProductAttributeSelection>[];

    for (final draft in _attributeDrafts) {
      final attributeId = draft.attribute?.id;
      final valueId = draft.value?.id;
      if (attributeId == null || valueId == null) continue;

      final key = '$attributeId:$valueId';
      if (!seen.add(key)) continue;

      selections.add(
        ProductAttributeSelection(
          productId: productId,
          attributeId: attributeId,
          attributeValueId: valueId,
        ),
      );
    }

    return selections;
  }

  String? _encodeAttributeDrafts(List<_ProductAttributeDraft> drafts) {
    final payload = drafts
        .where(
          (draft) => draft.attribute?.id != null && draft.value?.id != null,
        )
        .map((draft) => draft.toPayload())
        .toList();

    if (payload.isEmpty) return null;
    return jsonEncode(payload);
  }

  Future<List<_ProductAttributeDraft>> _decodeAttributeDrafts(
    String? rawValue,
  ) async {
    if (rawValue == null || rawValue.trim().isEmpty) return [];

    final decoded = jsonDecode(rawValue);
    if (decoded is! List) return [];

    final attributeController = Get.find<AttributeController>();
    final drafts = <_ProductAttributeDraft>[];

    for (final item in decoded) {
      if (item is! Map) continue;
      final attributeId = item['attribute_id'] as int?;
      final valueId = item['value_id'] as int?;
      if (attributeId == null || valueId == null) continue;

      final attribute = attributeController.attributes.firstWhereOrNull(
        (entry) => entry.id == attributeId,
      );
      if (attribute == null) continue;

      final values = await attributeController.loadValuesForAttribute(
        attributeId,
      );
      final value = values.firstWhereOrNull((entry) => entry.id == valueId);

      drafts.add(
        _ProductAttributeDraft(
          attribute: attribute,
          value: value,
          values: values,
        ),
      );
    }

    return drafts;
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

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const Gap(18),
          child,
        ],
      ),
    );
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProductAttributeSection() {
    if (_attributeDrafts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'no_attributes_selected_yet'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    final attributes = Get.find<AttributeController>().attributes.toList();
    return Column(
      children: _attributeDrafts.asMap().entries.map((entry) {
        final index = entry.key;
        final draft = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == _attributeDrafts.length - 1 ? 0 : 12,
          ),
          child: _ProductAttributeSelector(
            key: ValueKey('attribute-row-$index-${draft.attribute?.id}'),
            attributes: attributes,
            draft: draft,
            onAttributeChanged: (attribute) =>
                _selectAttribute(index, attribute),
            onValueChanged: (value) {
              setState(() {
                _attributeDrafts[index] = draft.copyWith(value: value);
              });
            },
            onRemove: () => _removeAttributeDraft(index),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = _editingProduct == null ? 'add_product'.tr : 'edit'.tr;
    final pageSubtitle = _editingProduct == null
        ? 'add_product_subtitle'.tr
        : 'edit_product_subtitle'.tr;

    if (_isLoading) {
      return AppScaffold(
        title: pageTitle,
        appBar: CustomAppBar(title: pageTitle, subtitle: pageSubtitle),
        includeDrawer: false,
        backgroundColor: const Color(0xFFF6F7FB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return AppScaffold(
      title: pageTitle,
      appBar: CustomAppBar(title: pageTitle, subtitle: pageSubtitle),
      includeDrawer: false,
      backgroundColor: const Color(0xFFF6F7FB),
      bottomNavigationBar: AppBottomActionBar(
        actionLabel: _editingProduct == null ? 'save_product'.tr : 'save'.tr,
        onPressed: _saveProduct,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
          child: Form(
            key: _formKey,
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
                          _editingProduct == null
                              ? 'create_product_btn'.tr
                              : 'edit_product_btn'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Gap(14),
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'product_name'.tr
                            : _nameController.text.trim(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        _hasVariant
                            ? 'manage_variants_subtitle'.tr
                            : 'manage_core_info_subtitle'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          height: 1.4,
                        ),
                      ),
                      const Gap(18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.package2,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'enable_variants_title'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: _hasVariant,
                              onChanged: (value) => setState(() {
                                _hasVariant = value;
                                if (value) {
                                  _attributeDrafts.clear();
                                }
                              }),
                            ),
                          ],
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
                      CustomTextField(
                        controller: _nameController,
                        label: 'product_name'.tr,
                        isRequired: true,
                        validator: _requiredTextValidator,
                      ),
                      const Gap(14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompact = constraints.maxWidth < 640;
                          final brandSelector = CustomNavSelector(
                            label: 'brands'.tr,
                            value: _selectedBrand?.name ?? '',
                            isRequired: true,
                            validator: (_) => _selectedBrand == null
                                ? 'required_field'.tr
                                : null,
                            onTap: () async {
                              final result = await Get.toNamed(
                                AppRoutes.brands,
                                arguments: {'isPicker': true},
                              );
                              if (result != null && result is Brand) {
                                setState(() => _selectedBrand = result);
                              }
                            },
                          );
                          final categorySelector = CustomNavSelector(
                            label: 'categories'.tr,
                            value: _selectedCategory?.name ?? '',
                            isRequired: true,
                            validator: (_) => _selectedCategory == null
                                ? 'required_field'.tr
                                : null,
                            onTap: () async {
                              final result = await Get.toNamed(
                                AppRoutes.categories,
                                arguments: {'isPicker': true},
                              );
                              if (result != null && result is Category) {
                                setState(() => _selectedCategory = result);
                              }
                            },
                          );

                          if (isCompact) {
                            return Column(
                              children: [
                                brandSelector,
                                const Gap(14),
                                categorySelector,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: brandSelector),
                              const Gap(14),
                              Expanded(child: categorySelector),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Gap(16),
                if (!_hasVariant)
                  _buildSectionCard(
                    title: 'inventory_pricing'.tr,
                    subtitle: 'inventory_pricing_subtitle'.tr,
                    child: Column(children: _buildInventoryFields()),
                  ),
                if (!_hasVariant) ...[
                  const Gap(16),
                  _buildSectionCard(
                    title: 'attributes'.tr,
                    subtitle: 'attributes_subtitle'.tr,
                    trailing: OutlinedButton.icon(
                      onPressed: _addAttributeDraft,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text('add'.tr),
                    ),
                    child: _buildProductAttributeSection(),
                  ),
                ],
                if (_hasVariant)
                  _buildSectionCard(
                    title: 'variants'.tr,
                    subtitle: 'variants_subtitle'.tr,
                    trailing: OutlinedButton.icon(
                      onPressed: _showVariantDialog,
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: Text('add_variant'.tr),
                    ),
                    child: Obx(() {
                      if (_variants.isEmpty) {
                        return Container(
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
                        );
                      }

                      return Column(
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          v.name ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          LucideIcons.pencil,
                                          size: 18,
                                        ),
                                        onPressed: () => _showVariantDialog(
                                          variant: v,
                                          index: index,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          LucideIcons.trash2,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _variants.remove(v),
                                      ),
                                    ],
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
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
