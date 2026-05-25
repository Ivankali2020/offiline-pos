import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/data/repositories/expense_repository.dart';
import 'package:abpos/models/expense.dart';
import 'package:get/get.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _repository = ExpenseRepository();
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxString searchQuery = ''.obs;
  // null = all types, otherwise 'expense' | 'capital' | 'drawing'
  final Rxn<String> selectedTransactionType = Rxn<String>();

  List<Expense> get filteredExpenses {
    final query = searchQuery.value.trim().toLowerCase();
    final type = selectedTransactionType.value;
    return expenses.where((expense) {
      final matchesType = type == null || expense.transactionType == type;
      if (!matchesType) return false;
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
