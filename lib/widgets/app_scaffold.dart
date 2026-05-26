import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBar,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottom,
    this.includeDrawer = false,
    this.backgroundColor,
  });

  final String title;
  final PreferredSizeWidget? appBar;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? bottom;
  final bool includeDrawer;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          appBar ??
          AppBar(title: Text(title), actions: actions, bottom: bottom),
      drawer: includeDrawer ? const _AppDrawer() : null,
      backgroundColor: backgroundColor ?? const Color(0xFFF6F7FB),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final selectedRoute = Get.currentRoute;
    final theme = Theme.of(context);
    final settingsController = Get.find<SettingsController>();

    Widget buildSectionLabel(String label) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      );
    }

    Widget buildItem(String title, String route, IconData icon) {
      final isSelected = selectedRoute == route;
      final color = isSelected
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface.withValues(alpha: 0.72);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pop(context);
              if (selectedRoute != route) {
                Get.toNamed(route);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 17, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Drawer(
      backgroundColor: const Color(0xFFF6F7FB),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        LucideIcons.store,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => Text(
                        _storeName(settingsController),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'workspace_subtitle'.tr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            buildSectionLabel('main'.tr),
            buildItem(
              'dashboard'.tr,
              AppRoutes.dashboard,
              LucideIcons.layoutDashboard,
            ),
            buildItem(
              'new_sale'.tr,
              AppRoutes.saleDetails,
              LucideIcons.shoppingCart,
            ),
            buildItem('orders'.tr, AppRoutes.orders, LucideIcons.history),
            buildSectionLabel('catalog'.tr),
            buildItem(
              'products'.tr,
              AppRoutes.productList,
              LucideIcons.package,
            ),
            buildItem('brands'.tr, AppRoutes.brands, LucideIcons.tag),
            buildItem(
              'categories'.tr,
              AppRoutes.categories,
              LucideIcons.layers,
            ),
            buildItem(
              'attributes'.tr,
              AppRoutes.attributes,
              LucideIcons.listTree,
            ),
            buildSectionLabel('finance'.tr),
            buildItem('suppliers'.tr, AppRoutes.suppliers, LucideIcons.truck),
            buildItem(
              'payments'.tr,
              AppRoutes.payments,
              Icons.account_balance_wallet_outlined,
            ),
            buildItem(
              'purchases'.tr,
              AppRoutes.purchases,
              Icons.inventory_2_rounded,
            ),
            buildItem(
              'expenses'.tr,
              AppRoutes.expenses,
              Icons.receipt_long_rounded,
            ),
            buildItem(
              'expense_categories'.tr,
              AppRoutes.expenseCategories,
              Icons.account_balance_wallet_rounded,
            ),
            buildSectionLabel('system'.tr),
            buildItem(
              'backup_restore'.tr,
              AppRoutes.backup,
              Icons.backup_table_rounded,
            ),
            buildItem(
              'import_data'.tr,
              AppRoutes.csvImport,
              Icons.upload_file_rounded,
            ),
            buildItem('settings'.tr, AppRoutes.settings, LucideIcons.settings),
          ],
        ),
      ),
    );
  }

  String _storeName(SettingsController controller) {
    final name = controller.settings.value?.storeName?.trim() ?? '';
    return name.isEmpty ? 'AB POS' : name;
  }
}
