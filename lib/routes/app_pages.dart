import 'package:get/get.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/pages/dashboard/dashboard_page.dart';
import 'package:abpos/pages/cart/cart_page.dart';
import 'package:abpos/pages/cart/product_picker_page.dart';
import 'package:abpos/pages/cart/sale_details_page.dart';
import 'package:abpos/pages/cart/checkout_page.dart';
import 'package:abpos/pages/order/order_history_page.dart';
import 'package:abpos/pages/order_return/order_return_page.dart';
import 'package:abpos/pages/order_return/order_return_form_page.dart';
import 'package:abpos/pages/purchase/purchase_create_page.dart';
import 'package:abpos/pages/purchase/purchase_history_page.dart';
import 'package:abpos/pages/purchase/purchase_product_picker_page.dart';
import 'package:abpos/pages/product/product_form_page.dart';
import 'package:abpos/pages/product/product_detail_page.dart';
import 'package:abpos/pages/product/product_list_page.dart';
import 'package:abpos/pages/settings/settings_page.dart';
import 'package:abpos/pages/manage/brand_page.dart';
import 'package:abpos/pages/manage/category_page.dart';
import 'package:abpos/pages/manage/attribute_form_page.dart';
import 'package:abpos/pages/manage/attribute_page.dart';
import 'package:abpos/pages/manage/payment_page.dart';
import 'package:abpos/pages/manage/supplier_page.dart';
import 'package:abpos/pages/expense/expense_category_page.dart';
import 'package:abpos/pages/expense/expense_chart_page.dart';
import 'package:abpos/pages/expense/expense_page.dart';
import 'package:abpos/pages/settings/backup_page.dart';
import 'package:abpos/pages/settings/import_page.dart';
import 'package:abpos/pages/manage/printer_page.dart';

abstract class AppPages {
  static const initial = AppRoutes.dashboard;

  static final routes = [
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardPage()),
    GetPage(name: AppRoutes.productList, page: () => const ProductListPage()),
    GetPage(
      name: AppRoutes.productDetail,
      page: () => const ProductDetailPage(),
    ),
    GetPage(name: AppRoutes.productForm, page: () => const ProductFormPage()),
    GetPage(name: AppRoutes.saleDetails, page: () => const SaleDetailsPage()),
    GetPage(name: AppRoutes.cart, page: () => const CartPage()),
    GetPage(
      name: AppRoutes.productPicker,
      page: () => const ProductPickerPage(),
    ),
    GetPage(name: AppRoutes.checkout, page: () => const CheckoutPage()),
    GetPage(name: AppRoutes.orders, page: () => const OrderHistoryPage()),
    GetPage(name: AppRoutes.orderReturns, page: () => const OrderReturnPage()),
    GetPage(name: AppRoutes.orderReturnCreate, page: () => const OrderReturnFormPage()),
    GetPage(name: AppRoutes.purchases, page: () => const PurchaseHistoryPage()),
    GetPage(
      name: AppRoutes.purchaseCreate,
      page: () => const PurchaseCreatePage(),
    ),
    GetPage(
      name: AppRoutes.purchaseProductPicker,
      page: () => const PurchaseProductPickerPage(),
    ),
    GetPage(name: AppRoutes.suppliers, page: () => const SupplierPage()),
    GetPage(name: AppRoutes.payments, page: () => const PaymentPage()),
    GetPage(name: AppRoutes.backup, page: () => const BackupPage()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    GetPage(name: AppRoutes.brands, page: () => const BrandPage()),
    GetPage(name: AppRoutes.categories, page: () => const CategoryPage()),
    GetPage(name: AppRoutes.attributes, page: () => const AttributePage()),
    GetPage(
      name: AppRoutes.attributeForm,
      page: () => const AttributeFormPage(),
    ),
    GetPage(
      name: AppRoutes.expenseCategories,
      page: () => const ExpenseCategoryPage(),
    ),
    GetPage(name: AppRoutes.expenses, page: () => const ExpensePage()),
    GetPage(
      name: AppRoutes.expenseCharts,
      page: () => const ExpenseChartPage(),
    ),
    GetPage(name: AppRoutes.csvImport, page: () => const ImportPage()),
    GetPage(name: AppRoutes.printers, page: () => const PrinterPage()),
  ];
}
