import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:get/get.dart';
import 'package:abpos/data/repositories/product_repository.dart';
import 'package:abpos/models/product.dart';
import 'package:abpos/models/product_attribute_selection.dart';

class ProductController extends GetxController {
  final ProductRepository _repository = ProductRepository();
  final RxList<Product> products = <Product>[].obs;
  final RxString searchQuery = ''.obs;

  // Filter states
  final RxnInt selectedBrandId = RxnInt();
  final RxnInt selectedCategoryId = RxnInt();
  final RxBool showEmptyStockOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    products.value = await _repository.findAll();
  }

  Future<int> insertProduct(Product product) async {
    final id = await _repository.insert(product);
    await loadProducts();
    _refreshDashboard();
    return id;
  }

  Future<void> updateProduct(Product product) async {
    await _repository.update(product);
    await loadProducts();
    _refreshDashboard();
  }

  Future<void> deleteProduct(int id) async {
    await _repository.delete(id);
    await loadProducts();
    _refreshDashboard();
  }

  void _refreshDashboard() {
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadMetrics();
    }
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }

  Future<List<ProductAttributeSelection>> loadAttributeSelections(
    int productId,
  ) {
    return _repository.findAttributeSelections(productId);
  }

  Future<void> saveAttributeSelections(
    int productId,
    List<ProductAttributeSelection> selections,
  ) {
    return _repository.replaceAttributeSelections(productId, selections);
  }

  void resetFilters() {
    selectedBrandId.value = null;
    selectedCategoryId.value = null;
    showEmptyStockOnly.value = false;
    searchQuery.value = '';
  }

  List<Product> get filteredProducts {
    final query = searchQuery.value.toLowerCase();

    return products.where((product) {
      // Search text filter
      bool matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          (product.sku?.toLowerCase().contains(query) ?? false);

      // Brand filter
      bool matchesBrand =
          selectedBrandId.value == null ||
          product.brandId == selectedBrandId.value;

      // Category filter
      bool matchesCategory =
          selectedCategoryId.value == null ||
          product.categoryId == selectedCategoryId.value;

      // Stock filter
      bool matchesStock =
          !showEmptyStockOnly.value || product.stockQuantity <= 0;

      return matchesSearch && matchesBrand && matchesCategory && matchesStock;
    }).toList();
  }
}
