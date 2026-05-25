import 'package:abpos/controllers/expense_controller.dart';
import 'package:abpos/data/repositories/expense_category_repository.dart';
import 'package:abpos/models/expense_category.dart';
import 'package:get/get.dart';

class ExpenseCategoryController extends GetxController {
  final ExpenseCategoryRepository _repository = ExpenseCategoryRepository();
  final RxList<ExpenseCategory> categories = <ExpenseCategory>[].obs;
  final RxString searchQuery = ''.obs;

  List<ExpenseCategory> get filteredCategories {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return categories;
    return categories.where((category) {
      final name = category.name.toLowerCase();
      final icon = category.icon?.toLowerCase() ?? '';
      return name.contains(query) || icon.contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final items = await _repository.findAll();
    categories.assignAll(items);
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _repository.insert(category);
    await loadCategories();
    await _refreshExpenses();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    await _repository.update(category);
    await loadCategories();
    await _refreshExpenses();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.delete(id);
    await loadCategories();
    await _refreshExpenses();
  }

  Future<void> _refreshExpenses() async {
    if (Get.isRegistered<ExpenseController>()) {
      await Get.find<ExpenseController>().loadExpenses();
    }
  }
}
