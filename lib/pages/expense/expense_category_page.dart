import 'package:abpos/controllers/expense_category_controller.dart';
import 'package:abpos/models/expense_category.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
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
      title: 'Expense Categories',
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'Expense Categories',
        subtitle: 'Organize recurring costs before recording expenses.',
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'Search expense categories',
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
            title: 'No expense categories yet',
            subtitle: 'Create a category like Rent, Delivery, or Utilities.',
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
      _SheetScaffold(
        title: category == null
            ? 'Add Expense Category'
            : 'Edit Expense Category',
        subtitle: 'Keep labels short so they work well in lists and reports.',
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: iconController,
              decoration: InputDecoration(
                labelText: 'Icon Text (optional)',
                hintText: 'For example: Rent or Gas',
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
                    onPressed: () async {
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
                    child: const Text('Save'),
                  ),
                ),
              ],
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
      _SheetScaffold(
        title: 'Delete Expense Category',
        subtitle: 'This category must not be used by any saved expense.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delete "${category.name}"?'),
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
                    onPressed: () async {
                      try {
                        await controller.deleteCategory(categoryId);
                        Get.back();
                      } catch (_) {
                        Get.back();
                        Get.snackbar(
                          'Unable to delete',
                          'Remove expenses in this category first.',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Delete'),
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
                      ? 'Icon label: $label'
                      : 'Used to group expense records.',
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

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({
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
