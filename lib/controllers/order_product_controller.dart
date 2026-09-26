import 'package:get/get.dart';
import 'package:abpos/data/repositories/order_product_repository.dart';
import 'package:abpos/models/order_product.dart';

class OrderProductController extends GetxController {
  final OrderProductRepository _repository = OrderProductRepository();
  final RxList<OrderProduct> orderProducts = <OrderProduct>[].obs;
  final RxString searchQuery = ''.obs;
  final Rxn<DateTime> filterStartDate = Rxn<DateTime>();
  final Rxn<DateTime> filterEndDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    loadOrderProducts();
  }

  Future<void> loadOrderProducts() async {
    final items = await _repository.findAll(
      startDate: filterStartDate.value,
      endDate: filterEndDate.value,
      search: searchQuery.value,
    );
    orderProducts.assignAll(items);
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  int get activeFilterCount {
    var count = 0;
    if (searchQuery.value.trim().isNotEmpty) count++;
    if (filterStartDate.value != null || filterEndDate.value != null) count++;
    return count;
  }

  void updateSearch(String value) {
    searchQuery.value = value;
    loadOrderProducts();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    filterStartDate.value = start;
    filterEndDate.value = end;
    loadOrderProducts();
  }

  void clearFilters() {
    searchQuery.value = '';
    filterStartDate.value = null;
    filterEndDate.value = null;
    loadOrderProducts();
  }

  double get totalProfit =>
      orderProducts.fold(0, (sum, item) => sum + item.profit);

  double get totalRevenue =>
      orderProducts.fold(0, (sum, item) => sum + item.price * item.quantity);

  int get totalQuantity =>
      orderProducts.fold(0, (sum, item) => sum + item.quantity);
}
