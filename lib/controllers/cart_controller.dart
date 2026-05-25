import 'package:get/get.dart';
import 'package:abpos/models/order_product.dart';
import 'package:abpos/models/product.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:intl/intl.dart';

class CartController extends GetxController {
  final RxList<OrderProduct> items = <OrderProduct>[].obs;

  // POS Sale State
  final RxString invoiceNumber = ''.obs;
  final Rx<DateTime> saleDate = DateTime.now().obs;
  final RxString customerName = ''.obs;
  final RxString customerPhone = ''.obs;
  final RxString note = ''.obs;

  // Financial State
  final RxDouble discountValue = 0.0.obs;
  final RxBool isPercentageDiscount = false.obs;
  final RxDouble deliveryFees = 0.0.obs;
  final RxDouble receivedAmount = 0.0.obs;
  final RxInt selectedPaymentId = 1.obs;
  final RxnInt selectedPaymentAccountId = RxnInt();
  final RxnString paymentImagePath = RxnString();

  @override
  void onInit() {
    super.onInit();
    generateInvoiceNumber();
  }

  void generateInvoiceNumber() {
    final now = DateTime.now();
    invoiceNumber.value = 'INV-${DateFormat('yyyyMMddHHmmss').format(now)}';
  }

  void addItem(OrderProduct item) {
    final existingIndex = items.indexWhere(
      (element) =>
          element.productId == item.productId &&
          element.variantId == item.variantId,
    );
    if (existingIndex >= 0) {
      final existing = items[existingIndex];
      items[existingIndex] = OrderProduct(
        id: existing.id,
        orderId: existing.orderId,
        productId: existing.productId,
        variantId: existing.variantId,
        attributes: existing.attributes,
        price: existing.price,
        discountPrice: existing.discountPrice,
        discount: existing.discount,
        quantity: existing.quantity + item.quantity,
        profit: existing.profit,
        originalBuyPrice: existing.originalBuyPrice,
        originalPrice: existing.originalPrice,
        totalRefundedAmount: existing.totalRefundedAmount,
        createdAt: existing.createdAt,
        updatedAt: existing.updatedAt,
        productName: existing.productName,
        variantName: existing.variantName,
      );
    } else {
      items.add(item);
    }
  }

  void addProduct(Product product, {int quantity = 1, int? variantId}) {
    final item = OrderProduct(
      orderId: 0,
      productId: product.id ?? 0,
      variantId: variantId,
      productName: product.name,
      attributes: null,
      price: product.sellPrice,
      discountPrice: product.sellPrice,
      discount: 0,
      quantity: quantity,
      profit: (product.sellPrice - product.buyPrice),
      originalBuyPrice: product.buyPrice,
      originalPrice: product.sellPrice,
      totalRefundedAmount: 0,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    addItem(item);
  }

  void updateQuantity(int index, int delta) {
    final item = items[index];
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      items.removeAt(index);
    } else {
      items[index] = OrderProduct(
        id: item.id,
        orderId: item.orderId,
        productId: item.productId,
        variantId: item.variantId,
        attributes: item.attributes,
        price: item.price,
        discountPrice: item.discountPrice,
        discount: item.discount,
        quantity: newQty,
        profit: item.profit,
        originalBuyPrice: item.originalBuyPrice,
        originalPrice: item.originalPrice,
        totalRefundedAmount: item.totalRefundedAmount,
        createdAt: item.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        productName: item.productName,
        variantName: item.variantName,
      );
    }
  }

  void removeItem(OrderProduct item) {
    items.remove(item);
  }

  void clearCart() {
    items.clear();
    customerName.value = '';
    customerPhone.value = '';
    note.value = '';
    discountValue.value = 0.0;
    deliveryFees.value = 0.0;
    receivedAmount.value = 0.0;
    selectedPaymentId.value = 1;
    selectedPaymentAccountId.value = null;
    paymentImagePath.value = null;
    generateInvoiceNumber();
    saleDate.value = DateTime.now();
  }

  void selectPayment(int paymentId) {
    selectedPaymentId.value = paymentId;
    selectedPaymentAccountId.value = null;
  }

  void selectPaymentAccount(int? accountId) {
    selectedPaymentAccountId.value = accountId;
  }

  void setPaymentImagePath(String? path) {
    paymentImagePath.value = path;
  }

  // Calculations
  double get subTotal =>
      items.fold<double>(0, (sum, item) => sum + item.price * item.quantity);

  double get discountAmount {
    if (isPercentageDiscount.value) {
      return subTotal * (discountValue.value / 100);
    }
    return discountValue.value;
  }

  double get taxRate {
    final settingsController = Get.find<SettingsController>();
    return settingsController.settings.value?.taxRate ?? 0.0;
  }

  double get taxAmount => (subTotal - discountAmount) * (taxRate / 100);

  double get totalAmount =>
      subTotal - discountAmount + taxAmount + deliveryFees.value;

  double get dueAmount => totalAmount - receivedAmount.value;

  int get totalQuantity =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);
}
