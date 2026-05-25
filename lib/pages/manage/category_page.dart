import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/controllers/category_controller.dart';
import 'package:abpos/models/category.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CategoryController>();
    final bool isPicker = Get.arguments?['isPicker'] ?? false;

    return AppScaffold(
      title: 'categories'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'categories'.tr,
        subtitle: 'manage_categories_subtitle'.tr,
        leadingIcon: isPicker ? LucideIcons.chevronLeft : LucideIcons.menu,
        onBackPressed: isPicker ? () => Get.back() : null,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_categories'.tr,
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
        final categories = controller.filteredCategories;
        if (categories.isEmpty) {
          return Center(child: Text('no_categories_found'.tr));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == categories.length - 1 ? 0 : 12,
              ),
              child: _CrudCard(
                icon: LucideIcons.layers,
                title: category.name,
                subtitle: category.description?.trim().isNotEmpty == true
                    ? category.description!.trim()
                    : 'no_description_yet'.tr,
                pickerLabel: isPicker ? 'tap_to_select'.tr : null,
                onTap: isPicker ? () => Get.back(result: category) : null,
                onEdit: () => _showCategorySheet(context, category: category),
                onDelete: () => _confirmDelete(context, category),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySheet(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, {Category? category}) {
    final controller = Get.find<CategoryController>();
    final nameController = TextEditingController(text: category?.name);
    final descriptionController = TextEditingController(
      text: category?.description,
    );

    Get.bottomSheet(
      isScrollControlled: true,
      _CrudSheet(
        title: category == null ? 'add_category'.tr : 'edit_category'.tr,
        subtitle: 'category_sheet_subtitle'.tr,
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'name'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'description'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) return;

                      final newCategory = Category(
                        id: category?.id,
                        sellerId: 1,
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        isSubCategory: false,
                      );

                      if (category == null) {
                        controller.addCategory(newCategory);
                      } else {
                        controller.updateCategory(newCategory);
                      }
                      Get.back();
                    },
                    child: Text('save'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    final controller = Get.find<CategoryController>();
    final categoryId = category.id;
    if (categoryId == null) return;

    Get.bottomSheet(
      _CrudSheet(
        title: 'delete_category'.tr,
        subtitle: 'delete_category_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_category_confirm'.trParams({'name': category.name})),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      controller.deleteCategory(categoryId);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('delete'.tr),
                  ),
                ),
              ],
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

class _CrudSheet extends StatelessWidget {
  const _CrudSheet({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
