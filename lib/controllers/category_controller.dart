import 'package:get/get.dart';
import 'package:abpos/data/repositories/category_repository.dart';
import 'package:abpos/models/category.dart';

class CategoryController extends GetxController {
  final CategoryRepository _repository = CategoryRepository();
  final RxList<Category> categories = <Category>[].obs;
  final RxString searchQuery = ''.obs;

  List<Category> get filteredCategories {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return categories;
    return categories.where((category) {
      final name = category.name.toLowerCase();
      final description = category.description?.toLowerCase() ?? '';
      return name.contains(query) || description.contains(query);
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

  Future<void> addCategory(Category category) async {
    await _repository.insert(category);
    await loadCategories();
  }

  Future<void> updateCategory(Category category) async {
    await _repository.update(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _repository.delete(id);
    await loadCategories();
  }
}
