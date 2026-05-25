import 'package:abpos/controllers/attribute_controller.dart';
import 'package:abpos/controllers/brand_controller.dart';
import 'package:abpos/controllers/cart_controller.dart';
import 'package:abpos/controllers/category_controller.dart';
import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/controllers/expense_category_controller.dart';
import 'package:abpos/controllers/expense_controller.dart';
import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/controllers/payment_controller.dart';
import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/controllers/purchase_cart_controller.dart';
import 'package:abpos/controllers/purchase_controller.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/controllers/supplier_controller.dart';
import 'package:get/get.dart';

class AppRefreshService {
  static Future<void> refreshAll() async {
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clearCart();
    }
    if (Get.isRegistered<PurchaseCartController>()) {
      Get.find<PurchaseCartController>().clearCart();
    }

    final futures = <Future<void>>[];

    if (Get.isRegistered<ProductController>()) {
      futures.add(Get.find<ProductController>().loadProducts());
    }
    if (Get.isRegistered<BrandController>()) {
      futures.add(Get.find<BrandController>().loadBrands());
    }
    if (Get.isRegistered<CategoryController>()) {
      futures.add(Get.find<CategoryController>().loadCategories());
    }
    if (Get.isRegistered<AttributeController>()) {
      futures.add(Get.find<AttributeController>().loadAttributes());
    }
    if (Get.isRegistered<OrderController>()) {
      futures.add(Get.find<OrderController>().loadOrders());
    }
    if (Get.isRegistered<PurchaseController>()) {
      futures.add(Get.find<PurchaseController>().loadPurchases());
    }
    if (Get.isRegistered<SupplierController>()) {
      futures.add(Get.find<SupplierController>().loadSuppliers());
    }
    if (Get.isRegistered<PaymentController>()) {
      futures.add(Get.find<PaymentController>().loadData());
    }
    if (Get.isRegistered<ExpenseController>()) {
      futures.add(Get.find<ExpenseController>().loadExpenses());
    }
    if (Get.isRegistered<ExpenseCategoryController>()) {
      futures.add(Get.find<ExpenseCategoryController>().loadCategories());
    }
    if (Get.isRegistered<SettingsController>()) {
      futures.add(Get.find<SettingsController>().loadSettings());
    }
    if (Get.isRegistered<DashboardController>()) {
      final dashboard = Get.find<DashboardController>();
      futures.add(dashboard.loadMetrics());
      futures.add(dashboard.loadInitialChartData());
    }

    await Future.wait(futures);
  }
}
