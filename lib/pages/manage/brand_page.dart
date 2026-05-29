import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/brand_controller.dart';
import 'package:abpos/models/brand.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';

class BrandPage extends StatefulWidget {
  const BrandPage({super.key});

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BrandController>();
    final bool isPicker = Get.arguments?['isPicker'] ?? false;

    return AppScaffold(
      title: 'brands'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'brands'.tr,
        subtitle: 'manage_brands_subtitle'.tr,
        leadingIcon: isPicker ? LucideIcons.chevronLeft : LucideIcons.menu,
        onBackPressed: isPicker ? () => Get.back() : null,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_brands'.tr,
                onChanged: (value) => controller.searchQuery.value = value,
                onClear: () {
                  _searchController.clear();
                  controller.searchQuery.value = '';
                },
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? LucideIcons.x : LucideIcons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
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
        ],
      ),
      body: Obx(() {
        final brands = controller.filteredBrands;
        if (brands.isEmpty) {
          return Center(child: Text('no_brands_found'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: brands.length,
          itemBuilder: (context, index) {
            final brand = brands[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == brands.length - 1 ? 0 : 12,
              ),
              child: _CrudCard(
                icon: LucideIcons.tag,
                title: brand.name,
                subtitle: brand.description?.trim().isNotEmpty == true
                    ? brand.description!.trim()
                    : 'no_description_yet'.tr,
                pickerLabel: isPicker ? 'tap_to_select'.tr : null,
                onTap: isPicker ? () => Get.back(result: brand) : null,
                onEdit: () => _showBrandSheet(context, brand: brand),
                onDelete: () => _confirmDelete(context, brand),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBrandSheet(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showBrandSheet(BuildContext context, {Brand? brand}) {
    final controller = Get.find<BrandController>();
    final nameController = TextEditingController(text: brand?.name);
    final descriptionController = TextEditingController(
      text: brand?.description,
    );

    Get.bottomSheet(
      isScrollControlled: true,
      CustomFormSheet(
        title: brand == null ? 'add_brand'.tr : 'edit_brand'.tr,
        subtitle: 'brand_sheet_subtitle'.tr,
        child: Column(
          children: [
            CustomTextField(
              controller: nameController,
              label: 'name'.tr,
              isRequired: true,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: descriptionController,
              label: 'description'.tr,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            FormActionButtons(
              onConfirm: () {
                if (nameController.text.trim().isEmpty) return;

                final newBrand = Brand(
                  id: brand?.id,
                  sellerId: 1,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                );

                if (brand == null) {
                  controller.addBrand(newBrand);
                } else {
                  controller.updateBrand(newBrand);
                }
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Brand brand) {
    final controller = Get.find<BrandController>();
    final brandId = brand.id;
    if (brandId == null) return;

    Get.bottomSheet(
      CustomFormSheet(
        title: 'delete_brand'.tr,
        subtitle: 'delete_brand_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_brand_confirm'.trParams({'name': brand.name})),
            const SizedBox(height: 20),
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () {
                controller.deleteBrand(brandId);
                Get.back();
              },
            ),
          ],
        ),
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

class _CrudCard extends StatelessWidget {
  const _CrudCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.pickerLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final String? pickerLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (pickerLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              pickerLabel!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(LucideIcons.pencil, size: 18),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


