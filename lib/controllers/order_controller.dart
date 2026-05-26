import 'package:get/get.dart';
import 'package:abpos/data/repositories/order_repository.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/order_product.dart';

import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/controllers/product_controller.dart';

enum OrderDateFilterPreset { today, thisWeek, thisMonth, custom }

class OrderController extends GetxController {
  final OrderRepository _repository = OrderRepository();
  final RxList<Order> orders = <Order>[].obs;
  final RxString invoiceFilter = ''.obs;
  final Rxn<DateTime> filterStartDate = Rxn<DateTime>();
  final Rxn<DateTime> filterEndDate = Rxn<DateTime>();
  final Rxn<OrderDateFilterPreset> selectedDatePreset =
      Rxn<OrderDateFilterPreset>();

  @override
  void onInit() {
    super.onInit();
    loadOrders();
  }

  Future<void> loadOrders() async {
    final items = await _repository.findAll();
    orders.assignAll(items);
  }

  List<Order> get filteredOrders {
    final query = invoiceFilter.value.trim().toLowerCase();
    final start = filterStartDate.value;
    final end = filterEndDate.value;

    return orders.where((order) {
      final matchesInvoice =
          query.isEmpty || order.invoiceNumber.toLowerCase().contains(query);
      final matchesDate = _matchesDateRange(order.createdAt, start, end);
      return matchesInvoice && matchesDate;
    }).toList();
  }

  double get filteredTotalSales =>
      filteredOrders.fold(0, (sum, order) => sum + order.totalPrice);

  bool get hasActiveFilters => activeFilterCount > 0;

  int get activeFilterCount {
    var count = 0;
    if (invoiceFilter.value.trim().isNotEmpty) {
      count++;
    }
    if (filterStartDate.value != null || filterEndDate.value != null) {
      count++;
    }
    return count;
  }

  void updateInvoiceFilter(String value) {
    invoiceFilter.value = value;
  }

  void applyDatePreset(OrderDateFilterPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case OrderDateFilterPreset.today:
        filterStartDate.value = today;
        filterEndDate.value = today;
        break;
      case OrderDateFilterPreset.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filterStartDate.value = startOfWeek;
        filterEndDate.value = endOfWeek;
        break;
      case OrderDateFilterPreset.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        filterStartDate.value = startOfMonth;
        filterEndDate.value = endOfMonth;
        break;
      case OrderDateFilterPreset.custom:
        break;
    }

    selectedDatePreset.value = preset;
  }

  void setCustomDateRange(DateTime? start, DateTime? end) {
    filterStartDate.value = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    filterEndDate.value = end == null
        ? null
        : DateTime(end.year, end.month, end.day);
    selectedDatePreset.value = start == null && end == null
        ? null
        : OrderDateFilterPreset.custom;
  }

  void clearDateFilter() {
    filterStartDate.value = null;
    filterEndDate.value = null;
    selectedDatePreset.value = null;
  }

  void clearFilters() {
    invoiceFilter.value = '';
    clearDateFilter();
  }

  bool _matchesDateRange(String? raw, DateTime? start, DateTime? end) {
    if (start == null && end == null) {
      return true;
    }

    if (raw == null || raw.trim().isEmpty) {
      return false;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return false;
    }

    final normalizedDate = DateTime(parsed.year, parsed.month, parsed.day);
    final normalizedStart = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    final normalizedEnd = end == null
        ? null
        : DateTime(end.year, end.month, end.day);

    if (normalizedStart != null && normalizedDate.isBefore(normalizedStart)) {
      return false;
    }
    if (normalizedEnd != null && normalizedDate.isAfter(normalizedEnd)) {
      return false;
    }
    return true;
  }

  Future<List<OrderProduct>> getOrderProducts(int orderId) async {
    return _repository.findProductsByOrderId(orderId);
  }

  void addOrder(Order order) {
    orders.add(order);
  }

  Future<Order> saveOrderWithProducts(
    Order order,
    List<OrderProduct> products,
  ) async {
    final orderId = await _repository.saveOrderWithProducts(order, products);
    await loadOrders();

    // Refresh Dashboard if it exists
    if (Get.isRegistered<DashboardController>()) {
      final dashboard = Get.find<DashboardController>();
      dashboard.loadMetrics();
      dashboard.loadChartData();
    }

    if (Get.isRegistered<ProductController>()) {
      Get.find<ProductController>().loadProducts();
    }

    return Order(
      id: orderId,
      invoiceNumber: order.invoiceNumber,
      sellerId: order.sellerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      status: order.status,
      subTotal: order.subTotal,
      deliveryFees: order.deliveryFees,
      totalPrice: order.totalPrice,
      paymentId: order.paymentId,
      paymentAccountId: order.paymentAccountId,
      tax: order.tax,
      taxPrice: order.taxPrice,
      givenAmount: order.givenAmount,
      changeAmount: order.changeAmount,
      note: order.note,
      imagePath: order.imagePath,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }

  Future<Order> checkout(
    List<OrderProduct> products, {
    required String customerName,
    required String customerPhone,
    required double subTotal,
    required double deliveryFees,
    required double totalPrice,
    required double tax,
    required double taxPrice,
    required double givenAmount,
    required double changeAmount,
    int? paymentId,
    int? paymentAccountId,
    String? note,
    String? imagePath,
  }) async {
    final order = Order(
      invoiceNumber: createInvoiceNumber(),
      sellerId: 1,
      customerName: customerName,
      customerPhone: customerPhone,
      status: 'completed',
      subTotal: subTotal,
      deliveryFees: deliveryFees,
      totalPrice: totalPrice,
      paymentId: paymentId ?? 1,
      paymentAccountId: paymentAccountId,
      tax: tax,
      taxPrice: taxPrice,
      givenAmount: givenAmount,
      changeAmount: changeAmount,
      note: note,
      imagePath: imagePath,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    return saveOrderWithProducts(order, products);
  }

  String createInvoiceNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'INV-$timestamp';
  }
}
