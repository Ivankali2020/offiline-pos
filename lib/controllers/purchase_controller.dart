import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/data/repositories/purchase_repository.dart';
import 'package:abpos/models/purchase.dart';
import 'package:abpos/models/purchase_product.dart';
import 'package:get/get.dart';

class PurchaseController extends GetxController {
  final PurchaseRepository _repository = PurchaseRepository();
  final RxList<Purchase> purchases = <Purchase>[].obs;
  final RxString invoiceFilter = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    final items = await _repository.findAll();
    purchases.assignAll(items);
  }

  List<Purchase> get filteredPurchases {
    final query = invoiceFilter.value.trim().toLowerCase();
    if (query.isEmpty) return purchases;
    return purchases.where((purchase) {
      return purchase.invoiceNumber.toLowerCase().contains(query) ||
          purchase.status.toLowerCase().contains(query) ||
          (purchase.note?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  double get filteredTotalAmount =>
      filteredPurchases.fold(0, (sum, purchase) => sum + purchase.totalAmount);

  Future<List<PurchaseProduct>> getPurchaseProducts(int purchaseId) {
    return _repository.findProductsByPurchaseId(purchaseId);
  }

  Future<Purchase> createPurchase(
    Purchase purchase,
    List<PurchaseProduct> products,
  ) async {
    final purchaseId = await _repository.savePurchaseWithProducts(
      purchase,
      products,
    );
    await loadPurchases();
    final saved = await _repository.findById(purchaseId);
    return saved ??
        Purchase(
          id: purchaseId,
          invoiceNumber: purchase.invoiceNumber,
          sellerId: purchase.sellerId,
          supplierId: purchase.supplierId,
          totalAmount: purchase.totalAmount,
          paidAmount: purchase.paidAmount,
          dueAmount: purchase.dueAmount,
          status: purchase.status,
          note: purchase.note,
          createdAt: purchase.createdAt,
          updatedAt: purchase.updatedAt,
        );
  }

  Future<Purchase?> reloadPurchase(int id) => _repository.findById(id);

  Future<void> completePurchase(int purchaseId) async {
    await _repository.completePurchase(purchaseId);
    await loadPurchases();
    if (Get.isRegistered<ProductController>()) {
      await Get.find<ProductController>().loadProducts();
    }
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadMetrics();
    }
  }
}
