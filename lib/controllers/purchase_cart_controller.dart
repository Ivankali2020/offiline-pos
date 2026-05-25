import 'package:abpos/models/product.dart';
import 'package:abpos/models/purchase_product.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PurchaseCartController extends GetxController {
  final RxList<PurchaseProduct> items = <PurchaseProduct>[].obs;
  final RxString invoiceNumber = ''.obs;
  final Rx<DateTime> purchaseDate = DateTime.now().obs;
  final RxString note = ''.obs;
  final RxDouble paidAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    generateInvoiceNumber();
  }

  void generateInvoiceNumber() {
    final now = DateTime.now();
    invoiceNumber.value = 'PUR-${DateFormat('yyyyMMddHHmmss').format(now)}';
  }

  void addProduct(
    Product product, {
    int quantity = 1,
    int? variantId,
    double? costPrice,
    double? sellPrice,
  }) {
    final existingIndex = items.indexWhere(
      (item) =>
          item.productId == (product.id ?? 0) && item.variantId == variantId,
    );
    final unitCost = costPrice ?? product.buyPrice;
    final unitSellPrice = sellPrice ?? product.sellPrice;
    if (existingIndex >= 0) {
      final current = items[existingIndex];
      final nextQuantity = current.quantity + quantity;
      items[existingIndex] = PurchaseProduct(
        id: current.id,
        purchaseId: current.purchaseId,
        productId: current.productId,
        variantId: current.variantId,
        quantity: nextQuantity,
        costPrice: unitCost,
        sellPrice: unitSellPrice,
        totalCost: unitCost * nextQuantity,
        createdAt: current.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        productName: current.productName,
        variantName: current.variantName,
      );
      return;
    }

    items.add(
      PurchaseProduct(
        purchaseId: 0,
        productId: product.id ?? 0,
        variantId: variantId,
        quantity: quantity,
        costPrice: unitCost,
        sellPrice: unitSellPrice,
        totalCost: unitCost * quantity,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        productName: product.name,
      ),
    );
  }

  void updateQuantity(int index, int delta) {
    final item = items[index];
    final nextQuantity = item.quantity + delta;
    if (nextQuantity <= 0) {
      items.removeAt(index);
      return;
    }
    items[index] = PurchaseProduct(
      id: item.id,
      purchaseId: item.purchaseId,
      productId: item.productId,
      variantId: item.variantId,
      quantity: nextQuantity,
      costPrice: item.costPrice,
      sellPrice: item.sellPrice,
      totalCost: item.costPrice * nextQuantity,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      productName: item.productName,
      variantName: item.variantName,
    );
  }

  void updateCostPrice(int index, double costPrice) {
    final item = items[index];
    items[index] = PurchaseProduct(
      id: item.id,
      purchaseId: item.purchaseId,
      productId: item.productId,
      variantId: item.variantId,
      quantity: item.quantity,
      costPrice: costPrice,
      sellPrice: item.sellPrice,
      totalCost: costPrice * item.quantity,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      productName: item.productName,
      variantName: item.variantName,
    );
  }

  void updateLine(
    int index, {
    required int quantity,
    required double costPrice,
    required double sellPrice,
  }) {
    final item = items[index];
    if (quantity <= 0) {
      items.removeAt(index);
      return;
    }
    items[index] = PurchaseProduct(
      id: item.id,
      purchaseId: item.purchaseId,
      productId: item.productId,
      variantId: item.variantId,
      quantity: quantity,
      costPrice: costPrice,
      sellPrice: sellPrice,
      totalCost: costPrice * quantity,
      createdAt: item.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      productName: item.productName,
      variantName: item.variantName,
    );
  }

  void removeItem(PurchaseProduct item) {
    items.remove(item);
  }

  void clearCart() {
    items.clear();
    note.value = '';
    paidAmount.value = 0.0;
    purchaseDate.value = DateTime.now();
    generateInvoiceNumber();
  }

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalCost);

  double get dueAmount => totalAmount - paidAmount.value;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
}
