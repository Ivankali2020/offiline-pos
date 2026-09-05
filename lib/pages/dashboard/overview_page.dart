import 'package:abpos/controllers/dashboard_controller.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  static final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return AppScaffold(
      title: 'overview'.tr,
      appBar: CustomAppBar(
        title: 'overview'.tr,
        subtitle: 'overview_subtitle'.tr,
        leadingIcon: LucideIcons.layoutDashboard,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            _OverviewGrid(controller: controller),
          ],
        ),
      ),
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
              value: OverviewPage._numberFormat.format(
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
              value: OverviewPage._numberFormat.format(
                controller.totalProfit.value,
              ),
              suffix: 'MMK',
              icon: LucideIcons.badgeDollarSign,
              color: const Color(0xFF7C3AED),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'returns'.tr,
              value: OverviewPage._numberFormat.format(
                controller.totalReturns.value,
              ),
              suffix: 'MMK',
              icon: Icons.assignment_return_rounded,
              color: const Color(0xFFF43F5E),
            ),
          ),
          Obx(
            () => _StatCard(
              label: 'expenses'.tr,
              value: OverviewPage._numberFormat.format(
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
              value: OverviewPage._numberFormat.format(
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
              value: OverviewPage._numberFormat.format(
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
