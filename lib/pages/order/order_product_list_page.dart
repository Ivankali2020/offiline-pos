import 'package:abpos/controllers/order_product_controller.dart';
import 'package:abpos/pages/order/order_product_filter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';

class OrderProductListPage extends StatelessWidget {
  const OrderProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderProductController>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return AppScaffold(
      title: 'order_products'.tr,
      appBar: CustomAppBar(
        title: 'order_products'.tr,
        subtitle: 'order_products_subtitle'.tr,
        leadingIcon: LucideIcons.listTree,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'filter'.tr,
                    onPressed: () =>
                        OrderProductFilterBottomSheet.show(context, controller),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: controller.activeFilterCount > 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (controller.activeFilterCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${controller.activeFilterCount}',
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
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final items = controller.orderProducts;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _OverviewCard(
                itemCount: items.length,
                totalProfit: controller.totalProfit,
                totalRevenue: controller.totalRevenue,
                currencyFormat: currencyFormat,
                hasActiveFilters: controller.hasActiveFilters,
              ),
            ),
            if (controller.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ActiveFilterBar(controller: controller),
              ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyState(
                      hasFilters: controller.hasActiveFilters,
                      onClear: controller.clearFilters,
                    )
                  : RefreshIndicator(
                      onRefresh: controller.loadOrderProducts,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OrderProductCard(
                              item: item,
                              currencyFormat: currencyFormat,
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.itemCount,
    required this.totalProfit,
    required this.totalRevenue,
    required this.currencyFormat,
    required this.hasActiveFilters,
  });

  final int itemCount;
  final double totalProfit;
  final double totalRevenue;
  final NumberFormat currencyFormat;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF1F2937)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hasActiveFilters ? 'filtered'.tr : 'all'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$itemCount ${'items'.tr}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _OverviewStat(
                label: 'revenue'.tr,
                value: currencyFormat.format(totalRevenue),
                suffix: 'MMK',
              ),
              const SizedBox(width: 20),
              _OverviewStat(
                label: 'profit'.tr,
                value: currencyFormat.format(totalProfit),
                suffix: 'MMK',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    suffix!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.controller});

  final OrderProductController controller;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (controller.searchQuery.value.isNotEmpty) {
      chips.add(
        Chip(
          label: Text(controller.searchQuery.value),
          onDeleted: () => controller.updateSearch(''),
          avatar: const Icon(Icons.search_rounded, size: 16),
        ),
      );
    }

    if (controller.filterStartDate.value != null ||
        controller.filterEndDate.value != null) {
      final fmt = DateFormat('dd MMM');
      final start = controller.filterStartDate.value;
      final end = controller.filterEndDate.value;
      String label;
      if (start != null && end != null) {
        label = '${fmt.format(start)} - ${fmt.format(end)}';
      } else if (start != null) {
        label = 'From ${fmt.format(start)}';
      } else {
        label = 'Until ${fmt.format(end!)}';
      }
      chips.add(
        Chip(
          label: Text(label),
          onDeleted: () => controller.setDateRange(null, null),
          avatar: const Icon(Icons.date_range_rounded, size: 16),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          ),
        ),
      ],
    );
  }
}

class _OrderProductCard extends StatelessWidget {
  const _OrderProductCard({
    required this.item,
    required this.currencyFormat,
  });

  final dynamic item;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = item.productName ?? 'Product #${item.productId}';
    final unitProfit = item.price - item.originalBuyPrice;
    final lineTotal = item.price * item.quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Order #${item.orderId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _DetailChip(
                label: 'price'.tr,
                value: currencyFormat.format(item.price),
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 12),
              _DetailChip(
                label: 'buy'.tr,
                value: currencyFormat.format(item.originalBuyPrice),
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _DetailChip(
                label: 'profit'.tr,
                value: currencyFormat.format(unitProfit),
                color: const Color(0xFF10B981),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'total'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    currencyFormat.format(lineTotal),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters ? Icons.filter_list_off_rounded : Icons.inventory_2_outlined,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters ? 'no_results'.tr : 'no_order_products'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters ? 'try_different_filters'.tr : 'order_products_empty'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: Text('clear_filters'.tr),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
