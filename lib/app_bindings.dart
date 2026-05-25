import 'package:get/get.dart';
import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/controllers/product_controller.dart';
import 'package:abpos/controllers/cart_controller.dart';
import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/controllers/brand_controller.dart';
import 'package:abpos/controllers/category_controller.dart';
import 'package:abpos/controllers/attribute_controller.dart';
import 'package:abpos/controllers/expense_category_controller.dart';
import 'package:abpos/controllers/expense_controller.dart';
import 'package:abpos/controllers/purchase_controller.dart';
import 'package:abpos/controllers/purchase_cart_controller.dart';
import 'package:abpos/controllers/payment_controller.dart';
import 'package:abpos/controllers/supplier_controller.dart';

class AppBindings extends Bindings {
  static Future<void> initServices() async {
    // 1. Initialize Database
    await DBProvider.instance.initDB();

    // 2. Initialize Global Controllers Permanently
    // Using permanent: true ensures they stay in memory throughout the app lifecycle
    Get.put(DashboardController(), permanent: true);
    Get.put(ProductController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(BrandController(), permanent: true);
    Get.put(CategoryController(), permanent: true);
    Get.put(AttributeController(), permanent: true);
    Get.put(ExpenseCategoryController(), permanent: true);
    Get.put(ExpenseController(), permanent: true);
    Get.put(PurchaseController(), permanent: true);
    Get.put(PurchaseCartController(), permanent: true);
    Get.put(PaymentController(), permanent: true);
    Get.put(SupplierController(), permanent: true);
  }

  @override
  void dependencies() {
    // Everything is now handled in initServices for maximum reliability
  }
}
