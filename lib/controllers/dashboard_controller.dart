import 'package:get/get.dart';
import 'package:abpos/data/repositories/dashboard_repository.dart';

enum DashboardDateFilterPreset { today, thisWeek, thisMonth, custom }

class DashboardController extends GetxController {
  final DashboardRepository _repository = DashboardRepository();
  final RxInt totalOrders = 0.obs;
  final RxDouble totalSales = 0.0.obs;
  final RxDouble totalProfit = 0.0.obs;
  final RxDouble totalReturns = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalCapital = 0.0.obs;
  final RxDouble totalAllExpenses = 0.0.obs;
  final RxInt productsInStock = 0.obs;
  final RxInt totalProducts = 0.obs;
  final RxList<DashboardTrendPoint> orderTrendPoints =
      <DashboardTrendPoint>[].obs;
  final Rxn<DateTime> chartStartDate = Rxn<DateTime>();
  final Rxn<DateTime> chartEndDate = Rxn<DateTime>();
  final Rxn<DashboardDateFilterPreset> chartSelectedPreset =
      Rxn<DashboardDateFilterPreset>();

  final RxDouble filteredSales = 0.0.obs;
  final RxDouble filteredProfit = 0.0.obs;
  final RxDouble filteredExpenses = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMetrics();
    loadInitialChartData();
  }

  Future<void> loadMetrics() async {
    final results = await Future.wait<dynamic>([
      _repository.countOrders(),
      _repository.totalSales(),
      _repository.totalProfit(),
      _repository.totalExpenses(),
      _repository.itemsInStock(),
      _repository.countProducts(),
      _repository.totalCapital(),
      _repository.totalAllExpenses(),
      _repository.totalReturnAmount(),
    ]);

    totalOrders.value = results[0] as int;
    totalSales.value = results[1] as double;
    totalReturns.value = results[8] as double;
    totalProfit.value = (results[2] as double) - totalReturns.value;
    totalExpenses.value = results[3] as double;
    productsInStock.value = results[4] as int;
    totalProducts.value = results[5] as int;
    totalCapital.value = results[6] as double;
    totalAllExpenses.value = results[7] as double;

    await loadFilteredMetrics();
  }

  Future<void> loadFilteredMetrics() async {
    final startDate = chartStartDate.value;
    final endDate = chartEndDate.value;

    DateTime start;
    DateTime end;

    if (startDate != null && endDate != null) {
      start = DateTime(startDate.year, startDate.month, startDate.day);
      end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } else if (startDate != null) {
      start = DateTime(startDate.year, startDate.month, startDate.day);
      end = DateTime(start.year, start.month, start.day, 23, 59, 59);
    } else if (endDate != null) {
      start = DateTime(endDate.year, endDate.month, endDate.day);
      end = DateTime(start.year, start.month, start.day, 23, 59, 59);
    } else {
      final now = DateTime.now();
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    final results = await Future.wait<dynamic>([
      _repository.totalSalesByDateRange(start, end),
      _repository.totalProfitByDateRange(start, end),
      _repository.totalExpensesByDateRange(start, end),
    ]);

    filteredSales.value = results[0] as double;
    filteredProfit.value = results[1] as double;
    filteredExpenses.value = results[2] as double;
  }

  double get actualProfit => totalProfit.value - (totalExpenses.value + totalCapital.value);
  double get profitMinusExpenses => totalProfit.value - totalAllExpenses.value;

  Future<void> loadChartData() async {
    final items = await _repository.orderTrend(
      startDate: chartStartDate.value,
      endDate: chartEndDate.value,
    );
    orderTrendPoints.assignAll(items);
  }

  Future<void> loadInitialChartData() async {
    _setChartDatePreset(DashboardDateFilterPreset.thisMonth);
    await loadChartData();

    if (orderTrendPoints.isEmpty) {
      final latest = await _repository.latestOrderDate();
      if (latest != null) {
        chartStartDate.value = DateTime(latest.year, latest.month, 1);
        chartEndDate.value = DateTime(latest.year, latest.month + 1, 0);
        chartSelectedPreset.value =
            null; // Clear preset so it shows the actual dates on UI
        await loadChartData();
      }
    }
  }

  void _setChartDatePreset(DashboardDateFilterPreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case DashboardDateFilterPreset.today:
        chartStartDate.value = today;
        chartEndDate.value = today;
        break;
      case DashboardDateFilterPreset.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        chartStartDate.value = startOfWeek;
        chartEndDate.value = endOfWeek;
        break;
      case DashboardDateFilterPreset.thisMonth:
        chartStartDate.value = DateTime(now.year, now.month, 1);
        chartEndDate.value = DateTime(now.year, now.month + 1, 0);
        break;
      case DashboardDateFilterPreset.custom:
        break;
    }

    chartSelectedPreset.value = preset;
  }

  Future<void> applyChartDatePreset(DashboardDateFilterPreset preset) async {
    _setChartDatePreset(preset);
    await Future.wait([
      loadChartData(),
      loadFilteredMetrics(),
    ]);
  }

  Future<void> setCustomChartDateRange(DateTime? start, DateTime? end) async {
    chartStartDate.value = start == null
        ? null
        : DateTime(start.year, start.month, start.day);
    chartEndDate.value = end == null
        ? null
        : DateTime(end.year, end.month, end.day);
    chartSelectedPreset.value = start == null && end == null
        ? null
        : DashboardDateFilterPreset.custom;
    await Future.wait([
      loadChartData(),
      loadFilteredMetrics(),
    ]);
  }

  Future<void> clearChartFilter() async {
    chartStartDate.value = null;
    chartEndDate.value = null;
    chartSelectedPreset.value = null;
    await Future.wait([
      loadChartData(),
      loadFilteredMetrics(),
    ]);
  }

  int get chartActiveFilterCount {
    // Don't count the default this-month preset as an active filter
    if (chartSelectedPreset.value == DashboardDateFilterPreset.thisMonth) {
      return 0;
    }
    if (chartStartDate.value != null || chartEndDate.value != null) {
      return 1;
    }
    return 0;
  }
}
