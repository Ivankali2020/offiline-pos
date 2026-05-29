import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/pages/dashboard/dashboard_chart_filter_bottom_sheet.dart';
import 'package:abpos/pages/dashboard/order_trend_chart.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/services/app_refresh_service.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return AppScaffold(
      title: 'dashboard'.tr,
      includeDrawer: true,
      appBar: CustomAppBar(
        title: 'dashboard'.tr,
        subtitle: 'dashboard_subtitle'.tr,
        leadingIcon: LucideIcons.settings,
        showDrawerButton: true,
        actions: [
          TextButton.icon(
            onPressed: () => _confirmTestSeedReset(context),
            icon: const Icon(Icons.storage_rounded, size: 18),
            label: Text('test_seed'.tr),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            _SectionHeader(
              title: 'overview'.tr,
              subtitle: 'overview_subtitle'.tr,
            ),
            const SizedBox(height: 14),
            _OverviewGrid(controller: controller),
            const SizedBox(height: 30),
            _SectionHeader(
              title: 'order_chart'.tr,
              subtitle: 'order_chart_subtitle'.tr,
              trailing: Obx(
                () => _FilterButton(
                  count: controller.chartActiveFilterCount,
                  onPressed: () =>
                      DashboardChartFilterBottomSheet.show(context, controller),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Obx(
              () => OrderTrendChart(
                points: controller.orderTrendPoints.toList(),
                filterLabel: _filterLabel(controller),
              ),
            ),
            const SizedBox(height: 30),
            _SectionHeader(
              title: 'quick_actions'.tr,
              subtitle: 'quick_actions_subtitle'.tr,
            ),
            const SizedBox(height: 14),
            const _QuickActionGrid(),
          ],
        ),
      ),
    );
  }

  static String _filterLabel(DashboardController controller) {
    final preset = controller.chartSelectedPreset.value;
    final start = controller.chartStartDate.value;
    final end = controller.chartEndDate.value;
    final formatter = DateFormat('dd MMM');

    switch (preset) {
      case DashboardDateFilterPreset.today:
        return 'today'.tr;
      case DashboardDateFilterPreset.thisWeek:
        return 'this_week'.tr;
      case DashboardDateFilterPreset.thisMonth:
        return 'this_month'.tr;
      case DashboardDateFilterPreset.custom:
      case null:
        if (start == null && end == null) return 'all_dates'.tr;
        if (start != null && end != null) {
          return 'date_range'.trParams({
            'start': formatter.format(start),
            'end': formatter.format(end),
          });
        }
        if (start != null) {
          return 'from_date'.trParams({'date': formatter.format(start)});
        }
        return 'until_date'.trParams({'date': formatter.format(end!)});
    }
  }

  Future<void> _confirmTestSeedReset(BuildContext context) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('reset_seed_title'.tr),
        content: Text('reset_seed_content'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('reset'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DBProvider.instance.resetAndSeedDatabase();
    await _refreshAfterTestSeed();
    Get.snackbar(
      'test_seed_complete'.tr,
      'test_seed_success'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _refreshAfterTestSeed() async {
    await AppRefreshService.refreshAll();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 680 ? 2 : 3;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final theme = Theme.of(context);
        final cards = [
          Obx(
            () => _StatCard(
              label: 'orders'.tr,
              value: '${controller.totalOrders.value}',
              icon: LucideIcons.shoppingBag,
              color: theme.colorScheme.primary,
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'total_sales'.tr,
              value: DashboardPage._numberFormat.format(
                controller.totalSales.value,
              ),
              suffix: 'MMK',
              icon: LucideIcons.banknote,
              color: const Color(0xFF1F9D55),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'gross_profit'.tr,
              value: DashboardPage._numberFormat.format(
                controller.totalProfit.value,
              ),
              suffix: 'MMK',
              icon: LucideIcons.badgeDollarSign,
              color: const Color(0xFF7C3AED),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'expenses'.tr,
              value: DashboardPage._numberFormat.format(
                controller.totalExpenses.value + controller.totalCapital.value,
              ),
              suffix: 'MMK',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFFDC2626),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'actual_profit'.tr,
              value: DashboardPage._numberFormat.format(
                controller.actualProfit,
              ),
              suffix: 'MMK',
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFF0F766E),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'profit_minus_expenses'.tr,
              value: DashboardPage._numberFormat.format(
                controller.profitMinusExpenses,
              ),
              suffix: 'MMK',
              icon: LucideIcons.wallet,
              color: const Color(0xFF0284C7),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'stock'.tr,
              value: '${controller.productsInStock.value}',
              icon: LucideIcons.package,
              color: const Color(0xFFF59E0B),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'total_products'.tr,
              value: '${controller.totalProducts.value}',
              icon: LucideIcons.layoutGrid,
              color: const Color(0xFF2563EB),
            ),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      suffix!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: Text('filter'.tr),
        ),
        if (count > 0)
          Positioned(
            right: -5,
            top: -6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}



class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 720 ? 2 : 3;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final actions = [
          _QuickActionData(
            'new_sale'.tr,
            'start_checkout'.tr,
            LucideIcons.shoppingCart,
            const Color(0xFF059669),
            () => Get.toNamed(AppRoutes.saleDetails),
          ),
          _QuickActionData(
            'history'.tr,
            'see_order_activity'.tr,
            LucideIcons.history,
            const Color(0xFFDC2626),
            () => Get.toNamed(AppRoutes.orders),
          ),
          _QuickActionData(
            'products'.tr,
            'browse_product_catalog'.tr,
            LucideIcons.layoutGrid,
            const Color(0xFF2563EB),
            () => Get.toNamed(AppRoutes.productList),
          ),
          _QuickActionData(
            'brands'.tr,
            'manage_brands_subtitle'.tr,
            LucideIcons.tag,
            const Color(0xFFEA580C),
            () => Get.toNamed(AppRoutes.brands),
          ),
          _QuickActionData(
            'categories'.tr,
            'manage_categories_subtitle'.tr,
            LucideIcons.layers,
            const Color(0xFF7C3AED),
            () => Get.toNamed(AppRoutes.categories),
          ),
          _QuickActionData(
            'attributes'.tr,
            'manage_attributes_subtitle'.tr,
            LucideIcons.listTree,
            const Color(0xFF0891B2),
            () => Get.toNamed(AppRoutes.attributes),
          ),
          _QuickActionData(
            'suppliers'.tr,
            'manage_purchase_vendors'.tr,
            LucideIcons.truck,
            const Color(0xFF0369A1),
            () => Get.toNamed(AppRoutes.suppliers),
          ),
          _QuickActionData(
            'payments'.tr,
            'manage_payment_methods'.tr,
            Icons.account_balance_wallet_outlined,
            const Color(0xFF0F766E),
            () => Get.toNamed(AppRoutes.payments),
          ),
          _QuickActionData(
            'purchases'.tr,
            'receive_stock_inventory'.tr,
            Icons.inventory_2_rounded,
            const Color(0xFF0F766E),
            () => Get.toNamed(AppRoutes.purchases),
          ),
          _QuickActionData(
            'expenses'.tr,
            'track_operating_costs'.tr,
            Icons.receipt_long_rounded,
            const Color(0xFFB91C1C),
            () => Get.toNamed(AppRoutes.expenses),
          ),
          _QuickActionData(
            'expense_categories'.tr,
            'organize_expense_types'.tr,
            Icons.account_balance_wallet_rounded,
            const Color(0xFF0F766E),
            () => Get.toNamed(AppRoutes.expenseCategories),
          ),
          _QuickActionData(
            'printers'.tr,
            'manage_printers_subtitle'.tr,
            LucideIcons.printer,
            const Color(0xFF6366F1),
            () => Get.toNamed(AppRoutes.printers),
          ),
          _QuickActionData(
            'settings'.tr,
            'update_store_setup'.tr,
            LucideIcons.settings,
            const Color(0xFF111827),
            () => Get.toNamed(AppRoutes.settings),
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: actions
              .map(
                (action) => SizedBox(
                  width: width,
                  child: _QuickActionCard(data: action),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionData {
  const _QuickActionData(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(shadow: false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(data.icon, color: data.color, size: 18),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_outward_rounded, size: 18),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                data.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                data.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}





BoxDecoration _cardDecoration({double radius = 22, bool shadow = true}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
    boxShadow: shadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ]
        : null,
  );
}
