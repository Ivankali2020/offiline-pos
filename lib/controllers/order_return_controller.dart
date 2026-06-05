import 'package:abpos/data/repositories/order_return_repository.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/order_return.dart';
import 'package:abpos/models/order_return_product.dart';
import 'package:abpos/services/app_refresh_service.dart';
import 'package:get/get.dart';

enum ReturnDateFilterPreset { today, thisWeek, thisMonth, custom }

class OrderReturnController extends GetxController {
  final OrderReturnRepository _repository = OrderReturnRepository();

  final RxList<OrderReturn> returns = <OrderReturn>[].obs;
  final RxBool isLoading = true.obs;

  // Filter state
  final RxString invoiceFilter = ''.obs;
  final Rxn<DateTime> filterStartDate = Rxn<DateTime>();
  final Rxn<DateTime> filterEndDate = Rxn<DateTime>();
  final Rxn<ReturnDateFilterPreset> selectedDatePreset =
      Rxn<ReturnDateFilterPreset>();

  @override
  void onInit() {
    super.onInit();
    loadReturns();
  }

  List<OrderReturn> get filteredReturns {
    final query = invoiceFilter.value.trim().toLowerCase();
    final start = filterStartDate.value;
    final end = filterEndDate.value;

    return returns.where((r) {
      final matchesInvoice =
          query.isEmpty ||
          r.invoiceNumber.toLowerCase().contains(query) ||
          (r.originalInvoiceNumber ?? '').toLowerCase().contains(query);
      final matchesDate = _matchesDateRange(r.createdAt, start, end);
      return matchesInvoice && matchesDate;
    }).toList();
  }

  double get filteredTotalRefunds =>
      filteredReturns.fold(0, (sum, r) => sum + r.totalRefundAmount);

  bool get hasActiveFilters => activeFilterCount > 0;

  int get activeFilterCount {
    var count = 0;
    if (invoiceFilter.value.trim().isNotEmpty) count++;
    if (filterStartDate.value != null || filterEndDate.value != null) count++;
    return count;
  }

  void updateInvoiceFilter(String value) {
    invoiceFilter.value = value;
  }

  void applyDatePreset(ReturnDateFilterPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case ReturnDateFilterPreset.today:
        filterStartDate.value = today;
        filterEndDate.value = today;
        break;
      case ReturnDateFilterPreset.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        filterStartDate.value = startOfWeek;
        filterEndDate.value = startOfWeek.add(const Duration(days: 6));
        break;
      case ReturnDateFilterPreset.thisMonth:
        filterStartDate.value = DateTime(now.year, now.month, 1);
        filterEndDate.value = DateTime(now.year, now.month + 1, 0);
        break;
      case ReturnDateFilterPreset.custom:
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
        : ReturnDateFilterPreset.custom;
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

  bool _matchesDateRange(DateTime? date, DateTime? start, DateTime? end) {
    if (start == null && end == null) return true;
    if (date == null) return false;

    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (start != null && normalizedDate.isBefore(start)) return false;
    if (end != null && normalizedDate.isAfter(end)) return false;
    return true;
  }

  Future<void> loadReturns() async {
    isLoading.value = true;
    try {
      final items = await _repository.getOrderReturns();
      returns.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }

  Future<OrderReturn?> getReturnDetail(int id) async {
    return _repository.getOrderReturn(id);
  }

  Future<void> deleteReturn(int id) async {
    await _repository.deleteOrderReturn(id);
    await loadReturns();
    AppRefreshService.refreshAll();
  }

  Future<OrderReturn?> createReturnFromOrder(
    Order order,
    List<OrderReturnProduct> returnProducts, {
    String? restockingDecision,
    String? paymentSlip,
  }) async {
    try {
      final orderReturn = OrderReturn(
        invoiceNumber: 'RET-${order.invoiceNumber}',
        orderId: order.id!,
        sellerId: order.sellerId,
        restockingDecision: restockingDecision,
        paymentSlip: paymentSlip,
      );
      final result = await _repository.createOrderReturn(
        orderReturn,
        returnProducts,
      );
      await loadReturns();
      return result;
    } catch (e) {
      Get.snackbar('error'.tr, e.toString());
      return null;
    }
  }
}
