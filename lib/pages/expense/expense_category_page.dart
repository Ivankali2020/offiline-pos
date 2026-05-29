import 'package:abpos/controllers/expense_category_controller.dart';
import 'package:abpos/models/expense_category.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExpenseCategoryPage extends StatefulWidget {
  const ExpenseCategoryPage({super.key});

  @override
  State<ExpenseCategoryPage> createState() => _ExpenseCategoryPageState();
}

class _ExpenseCategoryPageState extends State<ExpenseCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseCategoryController>();

    return AppScaffold(
      title: 'expense_categories'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'expense_categories'.tr,
        subtitle: 'expense_categories_subtitle'.tr,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_expense_categories'.tr,
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
          return _EmptyState(
            title: 'no_expense_categories'.tr,
            subtitle: 'expense_categories_empty_subtitle'.tr,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadCategories,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == categories.length - 1 ? 0 : 12,
                ),
                child: _CategoryCard(
                  category: category,
                  onEdit: () => _showCategorySheet(context, category: category),
                  onDelete: () => _confirmDelete(context, category),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySheet(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, {ExpenseCategory? category}) {
    final controller = Get.find<ExpenseCategoryController>();
    final nameController = TextEditingController(text: category?.name);
    final iconController = TextEditingController(text: category?.icon);

    Get.bottomSheet(
      isScrollControlled: true,
      CustomFormSheet(
        title: category == null
            ? 'add_expense_category'.tr
            : 'edit_expense_category'.tr,
        subtitle: 'expense_category_sheet_subtitle'.tr,
        child: Column(
          children: [
            CustomTextField(
              controller: nameController,
              label: 'category_name'.tr,
              isRequired: true,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: iconController,
              label: 'icon_text_optional'.tr,
            ),
            const SizedBox(height: 20),
            FormActionButtons(
              onConfirm: () async {
                if (nameController.text.trim().isEmpty) return;

                final now = DateTime.now().toIso8601String();
                final nextCategory = ExpenseCategory(
                  id: category?.id,
                  name: nameController.text.trim(),
                  icon: iconController.text.trim().isEmpty
                      ? null
                      : iconController.text.trim(),
                  createdAt: category?.createdAt ?? now,
                  updatedAt: now,
                );

                await (category == null
                    ? controller.addCategory(nextCategory)
                    : controller.updateCategory(nextCategory));
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ExpenseCategory category) {
    final controller = Get.find<ExpenseCategoryController>();
    final categoryId = category.id;
    if (categoryId == null) return;

    Get.bottomSheet(
      CustomFormSheet(
        title: 'delete_expense_category'.tr,
        subtitle: 'delete_expense_category_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_confirm_name'.tr.replaceAll('@name', category.name)),
            const SizedBox(height: 20),
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () async {
                try {
                  await controller.deleteCategory(categoryId);
                  Get.back();
                } catch (_) {
                  Get.back();
                  Get.snackbar(
                    'unable_to_delete'.tr,
                    'remove_expenses_first'.tr,
                  );
                }
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

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final ExpenseCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = category.icon?.trim();
    final hasLabel = label != null && label.isNotEmpty;

    return Container(
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: hasLabel
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF0F766E),
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasLabel
                      ? 'icon_label_is'.tr.replaceAll('@label', label)
                      : 'used_to_group_expenses'.tr,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.35),
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
            icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
          ),
        ],
      ),
    );
  }
}



class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
