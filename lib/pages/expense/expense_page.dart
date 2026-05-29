import 'package:abpos/controllers/expense_category_controller.dart';
import 'package:abpos/controllers/expense_controller.dart';
import 'package:abpos/models/expense.dart';
import 'package:abpos/models/expense_category.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_text_field.dart';
import 'package:abpos/widgets/form/custom_dropdown_field.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    final categoryController = Get.find<ExpenseCategoryController>();

    return AppScaffold(
      title: 'expenses'.tr,
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: CustomAppBar(
        title: 'expenses'.tr,
        subtitle: 'expenses_subtitle'.tr,
        titleWidget: _showSearch
            ? _SearchField(
                controller: _searchController,
                hintText: 'search_expenses'.tr,
                onChanged: (value) =>
                    expenseController.searchQuery.value = value,
                onClear: () {
                  _searchController.clear();
                  expenseController.searchQuery.value = '';
                },
              )
            : null,
        actions: [
          // Filter button with badge
          Obx(() {
            final count = expenseController.activeFilterCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(
                    LucideIcons.slidersHorizontal,
                    color: count > 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _showFilterSheet(context, expenseController, categoryController),
                  tooltip: 'filter'.tr,
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
          // Search button
          IconButton(
            icon: Icon(
              _showSearch ? LucideIcons.x : LucideIcons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () {
              setState(() {
                if (_showSearch) {
                  _searchController.clear();
                  expenseController.searchQuery.value = '';
                }
                _showSearch = !_showSearch;
              });
            },
          ),
        ],
      ),
      body: Obx(() {
        final categories = categoryController.categories.toList(
          growable: false,
        );
        final allExpenses = expenseController.expenses.toList(growable: false);
        final filteredExpenses = expenseController.filteredExpenses;
        final activeFilters = expenseController.activeFilterCount;

        if (categories.isEmpty) {
          return _MissingCategoryState(
            onPressed: () => Get.toNamed(AppRoutes.expenseCategories),
          );
        }

        if (allExpenses.isEmpty) {
          return _EmptyExpenseState(
            onPressed: () => _showExpenseSheet(context),
          );
        }

        return Column(
          children: [
            // Active filter chips
            if (activeFilters > 0)
              _ActiveFilterChips(
                controller: expenseController,
                categories: categories,
                onClearAll: () {
                  _searchController.clear();
                  expenseController.clearAllFilters();
                },
              ),
            Expanded(
              child: filteredExpenses.isEmpty
                  ? _EmptySearchState(
                      onClear: () {
                        _searchController.clear();
                        expenseController.clearAllFilters();
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: expenseController.loadExpenses,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        children: [
                          _ExpenseOverview(
                            totalEntries: filteredExpenses.length,
                            totalAmount: expenseController.filteredTotalAmount,
                            totalCategories: categories.length,
                            currencyFormat: _currencyFormat,
                            onViewCharts: () =>
                                Get.toNamed(AppRoutes.expenseCharts),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _SectionLabel(
                                  title: 'recent_expenses'.tr,
                                  subtitle:
                                      'records_ready_to_review'.tr.replaceAll('@count', '${filteredExpenses.length}'),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    Get.toNamed(AppRoutes.expenseCategories),
                                icon: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 16,
                                ),
                                label: const Text('Categories'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...filteredExpenses.asMap().entries.map((entry) {
                            final index = entry.key;
                            final expense = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: index == filteredExpenses.length - 1
                                    ? 0
                                    : 12,
                              ),
                              child: _ExpenseCard(
                                expense: expense,
                                currencyFormat: _currencyFormat,
                                onEdit: () => _showExpenseSheet(
                                  context,
                                  expense: expense,
                                ),
                                onDelete: () =>
                                    _confirmDelete(context, expense: expense),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: Text('add_expense'.tr),
      ),
    );
  }

  // ── FILTER SHEET ─────────────────────────────────────────────────────────────
  void _showFilterSheet(
    BuildContext context,
    ExpenseController expenseController,
    ExpenseCategoryController categoryController,
  ) {
    // Capture current values to track pending changes within the sheet
    String? tempType = expenseController.selectedTransactionType.value;
    String? tempDateLabel = expenseController.selectedDateRangeLabel.value;
    int? tempCategoryId = expenseController.selectedCategoryId.value;
    DateTime? tempCustomStart = expenseController.customDateStart.value;
    DateTime? tempCustomEnd = expenseController.customDateEnd.value;

    final categories = categoryController.categories.toList(growable: false);

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (context, setModalState) {
          return CustomFormSheet(
            title: 'filter'.tr,
            subtitle: 'filter_expenses_subtitle'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Transaction Type ──────────────────────────────────────
                Text(
                  'transaction_type'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SheetFilterChip(
                      label: 'all'.tr,
                      isSelected: tempType == null,
                      onTap: () => setModalState(() => tempType = null),
                    ),
                    _SheetFilterChip(
                      label: 'expense'.tr.capitalizeFirst ?? 'Expense',
                      isSelected: tempType == 'expense',
                      onTap: () => setModalState(() => tempType = 'expense'),
                    ),
                    _SheetFilterChip(
                      label: 'capital'.tr,
                      isSelected: tempType == 'capital',
                      onTap: () => setModalState(() => tempType = 'capital'),
                    ),
                    _SheetFilterChip(
                      label: 'drawing'.tr,
                      isSelected: tempType == 'drawing',
                      onTap: () => setModalState(() => tempType = 'drawing'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Date Range ────────────────────────────────────────────
                Text(
                  'date_range_label'.tr,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SheetFilterChip(
                      label: 'all_time'.tr,
                      isSelected: tempDateLabel == null,
                      onTap: () => setModalState(() {
                        tempDateLabel = null;
                        tempCustomStart = null;
                        tempCustomEnd = null;
                      }),
                    ),
                    _SheetFilterChip(
                      label: 'this_month'.tr,
                      isSelected: tempDateLabel == 'this_month',
                      onTap: () => setModalState(() {
                        tempDateLabel = 'this_month';
                        tempCustomStart = null;
                        tempCustomEnd = null;
                      }),
                    ),
                    _SheetFilterChip(
                      label: 'last_month'.tr,
                      isSelected: tempDateLabel == 'last_month',
                      onTap: () => setModalState(() {
                        tempDateLabel = 'last_month';
                        tempCustomStart = null;
                        tempCustomEnd = null;
                      }),
                    ),
                    _SheetFilterChip(
                      label: 'custom_range'.tr,
                      isSelected: tempDateLabel == 'custom',
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: now,
                          initialDateRange: (tempCustomStart != null && tempCustomEnd != null)
                              ? DateTimeRange(start: tempCustomStart!, end: tempCustomEnd!)
                              : DateTimeRange(
                                  start: DateTime(now.year, now.month, 1),
                                  end: now,
                                ),
                        );
                        if (picked != null) {
                          setModalState(() {
                            tempDateLabel = 'custom';
                            tempCustomStart = picked.start;
                            tempCustomEnd = picked.end;
                          });
                        }
                      },
                    ),
                  ],
                ),
                // Show selected custom range
                if (tempDateLabel == 'custom' && tempCustomStart != null && tempCustomEnd != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.calendar, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(tempCustomStart!)} – ${DateFormat('dd MMM yyyy').format(tempCustomEnd!)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Category ──────────────────────────────────────────────
                if (categories.isNotEmpty) ...[
                  Text(
                    'category'.tr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SheetFilterChip(
                        label: 'all'.tr,
                        isSelected: tempCategoryId == null,
                        onTap: () => setModalState(() => tempCategoryId = null),
                      ),
                      ...categories.map((cat) => _SheetFilterChip(
                            label: cat.name,
                            isSelected: tempCategoryId == cat.id,
                            onTap: () => setModalState(() => tempCategoryId = cat.id),
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Actions ───────────────────────────────────────────────
                FormActionButtons(
                  cancelLabel: 'clear_filters'.tr,
                  confirmLabel: 'apply_filters'.tr,
                  confirmIcon: LucideIcons.check,
                  onCancel: () {
                    setModalState(() {
                      tempType = null;
                      tempDateLabel = null;
                      tempCategoryId = null;
                      tempCustomStart = null;
                      tempCustomEnd = null;
                    });
                    expenseController.clearAllFilters();
                    Get.back();
                  },
                  onConfirm: () {
                    expenseController.selectedTransactionType.value = tempType;
                    expenseController.selectedDateRangeLabel.value = tempDateLabel;
                    expenseController.selectedCategoryId.value = tempCategoryId;
                    expenseController.customDateStart.value = tempCustomStart;
                    expenseController.customDateEnd.value = tempCustomEnd;
                    Get.back();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── EXPENSE FORM SHEET ────────────────────────────────────────────────────────
  void _showExpenseSheet(BuildContext context, {Expense? expense}) {
    final expenseController = Get.find<ExpenseController>();
    final categoryController = Get.find<ExpenseCategoryController>();
    final categories = categoryController.categories.toList(growable: false);

    if (categories.isEmpty) {
      Get.snackbar(
        'expense_categories_needed'.tr,
        'create_expense_category_first'.tr,
      );
      Get.toNamed(AppRoutes.expenseCategories);
      return;
    }

    final amountController = TextEditingController(
      text: expense == null || expense.amount == 0
          ? ''
          : expense.amount.toStringAsFixed(
              expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
            ),
    );
    final paymentMethodController = TextEditingController(
      text: expense?.paymentMethod ?? 'Cash',
    );
    final descriptionController = TextEditingController(
      text: expense?.description,
    );
    var selectedCategoryId = expense?.categoryId ?? categories.first.id;
    var selectedDate = _parseExpenseDate(expense?.createdAt) ?? DateTime.now();
    var selectedTransactionType = expense?.transactionType ?? 'expense';

    Get.bottomSheet(
      isScrollControlled: true,
      StatefulBuilder(
        builder: (context, setModalState) {
          return CustomFormSheet(
            title: expense == null ? 'add_expense'.tr : 'edit_expense'.tr,
            subtitle: 'expense_sheet_subtitle'.tr,
            child: Column(
              children: [
                CustomDropdownField<String>(
                  value: selectedTransactionType,
                  label: 'transaction_type'.tr,
                  items: [
                    DropdownMenuItem(value: 'expense', child: Text('expense'.tr)),
                    DropdownMenuItem(value: 'capital', child: Text('capital'.tr)),
                    DropdownMenuItem(value: 'drawing', child: Text('drawing'.tr)),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setModalState(() => selectedTransactionType = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                CustomDropdownField<int>(
                  value: selectedCategoryId,
                  label: 'expense_category_label'.tr,
                  items: categories
                      .where((category) => category.id != null)
                      .map(
                        (category) => DropdownMenuItem<int>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setModalState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: amountController,
                  label: 'amount'.tr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: paymentMethodController,
                        label: 'payment_method'.tr,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: CustomTextField(
                        label: 'expense_date'.tr,
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('dd MMM yyyy').format(selectedDate),
                        ),
                        suffixIcon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            if (!context.mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selectedDate),
                            );
                            if (pickedTime != null) {
                              if (!context.mounted) return;
                              setModalState(() {
                                selectedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            } else {
                              setModalState(() {
                                selectedDate = pickedDate;
                              });
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  controller: descriptionController,
                  label: 'description'.tr,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                FormActionButtons(
                  onConfirm: () async {
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (selectedCategoryId == null ||
                        amount == null ||
                        amount <= 0) {
                      Get.snackbar(
                        'missing_details'.tr,
                        'choose_category_and_amount'.tr,
                      );
                      return;
                    }

                    final now = DateTime.now().toIso8601String();
                    final nextExpense = Expense(
                      id: expense?.id,
                      categoryId:
                          selectedCategoryId ?? categories.first.id!,
                      amount: amount,
                      description:
                          descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      paymentMethod:
                          paymentMethodController.text.trim().isEmpty
                          ? 'Cash'
                          : paymentMethodController.text.trim(),
                      transactionType: selectedTransactionType,
                      createdAt: selectedDate.toIso8601String(),
                      updatedAt: now,
                    );

                    await (expense == null
                        ? expenseController.addExpense(nextExpense)
                        : expenseController.updateExpense(nextExpense));
                    Get.back();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, {required Expense expense}) {
    final controller = Get.find<ExpenseController>();
    final expenseId = expense.id;
    if (expenseId == null) return;

    Get.bottomSheet(
      CustomFormSheet(
        title: 'delete_expense'.tr,
        subtitle: 'delete_expense_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('delete_confirm_name'.tr.replaceAll('@name', expense.categoryName ?? 'this expense')),
            const SizedBox(height: 20),
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () async {
                await controller.deleteExpense(expenseId);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _parseExpenseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

// ── ACTIVE FILTER CHIPS ─────────────────────────────────────────────────────────
class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.controller,
    required this.categories,
    required this.onClearAll,
  });

  final ExpenseController controller;
  final List<ExpenseCategory> categories;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final type = controller.selectedTransactionType.value;
      final dateLabel = controller.selectedDateRangeLabel.value;
      final catId = controller.selectedCategoryId.value;
      final customStart = controller.customDateStart.value;
      final customEnd = controller.customDateEnd.value;

      final chips = <Widget>[];

      if (type != null) {
        chips.add(_ActiveChip(
          label: type.tr.capitalizeFirst ?? type.tr,
          onRemove: () => controller.selectedTransactionType.value = null,
        ));
      }
      if (dateLabel != null) {
        String label;
        if (dateLabel == 'this_month') {
          label = 'this_month'.tr;
        } else if (dateLabel == 'last_month') {
          label = 'last_month'.tr;
        } else if (dateLabel == 'custom' && customStart != null && customEnd != null) {
          label = '${DateFormat('dd MMM').format(customStart)} – ${DateFormat('dd MMM yyyy').format(customEnd)}';
        } else {
          label = dateLabel;
        }
        chips.add(_ActiveChip(
          label: label,
          onRemove: () {
            controller.selectedDateRangeLabel.value = null;
            controller.customDateStart.value = null;
            controller.customDateEnd.value = null;
          },
        ));
      }
      if (catId != null) {
        final cat = categories.firstWhereOrNull((c) => c.id == catId);
        chips.add(_ActiveChip(
          label: cat?.name ?? 'Category',
          onRemove: () => controller.selectedCategoryId.value = null,
        ));
      }

      if (chips.isEmpty) return const SizedBox.shrink();

      return Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chips
                      .map((chip) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: chip,
                          ))
                      .toList(),
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'clear_all'.tr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              LucideIcons.x,
              size: 13,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SEARCH FIELD ────────────────────────────────────────────────────────────────
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

// ── OVERVIEW ────────────────────────────────────────────────────────────────────
class _ExpenseOverview extends StatelessWidget {
  const _ExpenseOverview({
    required this.totalEntries,
    required this.totalAmount,
    required this.totalCategories,
    required this.currencyFormat,
    required this.onViewCharts,
  });

  final int totalEntries;
  final double totalAmount;
  final int totalCategories;
  final NumberFormat currencyFormat;
  final VoidCallback onViewCharts;

  @override
  Widget build(BuildContext context) {
    final averageAmount = totalEntries == 0 ? 0 : totalAmount / totalEntries;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
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
                child: Text(
                  'expense_overview'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewCharts,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(LucideIcons.chartPie, size: 16),
                label: Text(
                  'charts'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'records_in_view'.tr.replaceAll('@count', '$totalEntries'),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _OverviewTile(
                  label: 'total_expense'.tr,
                  value: 'MMK ${currencyFormat.format(totalAmount)}',
                ),
              ),
              SizedBox(
                width: 150,
                child: _OverviewTile(
                  label: 'avg_entry'.tr,
                  value: 'MMK ${currencyFormat.format(averageAmount)}',
                ),
              ),
              SizedBox(
                width: 120,
                child: _OverviewTile(
                  label: 'categories'.tr,
                  value: '$totalCategories',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

// ── EXPENSE CARD ────────────────────────────────────────────────────────────────
class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.expense,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parsedDate = expense.createdAt == null
        ? null
        : DateTime.tryParse(expense.createdAt!);
    final dateLabel = parsedDate == null
        ? 'No date'
        : DateFormat('dd MMM yyyy').format(parsedDate);
    final description = expense.description?.trim();
    final iconLabel = expense.categoryIcon?.trim();
    final hasIconLabel = iconLabel != null && iconLabel.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFB91C1C).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: hasIconLabel
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            iconLabel,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFFB91C1C),
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
                      expense.categoryName ?? 'Expense',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFB91C1C).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'MMK ${currencyFormat.format(expense.amount)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.payments_outlined,
                      label: expense.paymentMethod,
                    ),
                    _InfoChip(
                      icon: Icons.category_outlined,
                      label: expense.categoryName ?? 'Expense',
                    ),
                    _InfoChip(
                      icon: LucideIcons.arrowRightLeft,
                      label:
                          expense.transactionType.tr.capitalizeFirst ??
                          expense.transactionType.tr,
                    ),
                  ],
                ),
              ),
              _ExpenseActionButton(
                tooltip: 'Edit expense',
                icon: LucideIcons.pencil,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
                onPressed: onEdit,
              ),
              const SizedBox(width: 6),
              _ExpenseActionButton(
                tooltip: 'Delete expense',
                icon: LucideIcons.trash2,
                color: Colors.red,
                backgroundColor: Colors.red.withValues(alpha: 0.08),
                onPressed: onDelete,
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.34,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseActionButton extends StatelessWidget {
  const _ExpenseActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}



// ── FILTER CHIP (in filter sheet) ────────────────────────────────────────────
class _SheetFilterChip extends StatelessWidget {
  const _SheetFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }
}

// ── STATE CARDS ───────────────────────────────────────────────────────────────
class _MissingCategoryState extends StatelessWidget {
  const _MissingCategoryState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.category_rounded,
      title: 'Create an expense category first',
      message:
          'Expenses need a category so reports and dashboard totals stay readable.',
      action: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Open Expense Categories'),
      ),
    );
  }
}

class _EmptyExpenseState extends StatelessWidget {
  const _EmptyExpenseState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.receipt_long_rounded,
      title: 'No expenses yet',
      message:
          'Add rent, transport, utilities, salaries, or any other operating cost here.',
      action: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Add Expense'),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: LucideIcons.searchX,
      title: 'No matching expenses',
      message: 'Try a different search term or clear the current filter.',
      action: OutlinedButton(
        onPressed: onClear,
        child: const Text('Clear Filters'),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.72,
                ),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }
}


