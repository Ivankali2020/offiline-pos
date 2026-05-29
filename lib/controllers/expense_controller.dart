import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/data/repositories/expense_repository.dart';
import 'package:abpos/models/expense.dart';
import 'package:get/get.dart';

class ExpenseDateRange {
  final DateTime start;
  final DateTime end;
  const ExpenseDateRange({required this.start, required this.end});
}

class ExpenseController extends GetxController {
  final ExpenseRepository _repository = ExpenseRepository();
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxString searchQuery = ''.obs;

  // null = all types, otherwise 'expense' | 'capital' | 'drawing'
  final Rxn<String> selectedTransactionType = Rxn<String>();

  // null = all categories, otherwise category id
  final Rxn<int> selectedCategoryId = Rxn<int>();

  // Date range label: null | 'this_month' | 'last_month' | 'custom'
  final Rxn<String> selectedDateRangeLabel = Rxn<String>();
  final Rxn<DateTime> customDateStart = Rxn<DateTime>();
  final Rxn<DateTime> customDateEnd = Rxn<DateTime>();

  int get activeFilterCount {
    int count = 0;
    if (selectedTransactionType.value != null) count++;
    if (selectedCategoryId.value != null) count++;
    if (selectedDateRangeLabel.value != null) count++;
    return count;
  }

  ExpenseDateRange? get effectiveDateRange {
    final label = selectedDateRangeLabel.value;
    if (label == null) return null;
    final now = DateTime.now();
    if (label == 'this_month') {
      return ExpenseDateRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 1).subtract(const Duration(microseconds: 1)),
      );
    } else if (label == 'last_month') {
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final lastYear = now.month == 1 ? now.year - 1 : now.year;
      return ExpenseDateRange(
        start: DateTime(lastYear, lastMonth, 1),
        end: DateTime(lastYear, lastMonth + 1, 1).subtract(const Duration(microseconds: 1)),
      );
    } else if (label == 'custom') {
      final s = customDateStart.value;
      final e = customDateEnd.value;
      if (s != null && e != null) return ExpenseDateRange(start: s, end: e);
    }
    return null;
  }

  List<Expense> get filteredExpenses {
    final query = searchQuery.value.trim().toLowerCase();
    final type = selectedTransactionType.value;
    final catId = selectedCategoryId.value;
    final range = effectiveDateRange;

    return expenses.where((expense) {
      if (type != null && expense.transactionType != type) return false;
      if (catId != null && expense.categoryId != catId) return false;
      if (range != null) {
        final date = expense.createdAt != null ? DateTime.tryParse(expense.createdAt!) : null;
        if (date == null) return false;
        if (date.isBefore(range.start) || date.isAfter(range.end)) return false;
      }
      if (query.isEmpty) return true;
      final categoryName = expense.categoryName?.toLowerCase() ?? '';
      final paymentMethod = expense.paymentMethod.toLowerCase();
      final description = expense.description?.toLowerCase() ?? '';
      return categoryName.contains(query) ||
          paymentMethod.contains(query) ||
          description.contains(query);
    }).toList();
  }

  double get filteredTotalAmount =>
      filteredExpenses.fold(0, (sum, expense) => sum + expense.amount);

  void clearAllFilters() {
    selectedTransactionType.value = null;
    selectedCategoryId.value = null;
    selectedDateRangeLabel.value = null;
    customDateStart.value = null;
    customDateEnd.value = null;
    searchQuery.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final items = await _repository.findAll();
    expenses.assignAll(items);
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.insert(expense);
    await loadExpenses();
    await _refreshDashboard();
  }

  Future<void> updateExpense(Expense expense) async {
    await _repository.update(expense);
    await loadExpenses();
    await _refreshDashboard();
  }

  Future<void> deleteExpense(int id) async {
    await _repository.delete(id);
    await loadExpenses();
    await _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadMetrics();
    }
  }
}
