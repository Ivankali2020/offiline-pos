import 'package:abpos/models/order.dart';
import 'package:abpos/pages/order/order_filter_bottom_sheet.dart';
import 'package:abpos/pages/order/order_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrderController>();
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return AppScaffold(
      title: 'Order History',
      appBar: CustomAppBar(
        title: 'Order History',
        subtitle: 'Track every sale and open receipt details instantly.',
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Filter orders',
                    onPressed: () =>
                        OrderFilterBottomSheet.show(context, controller),
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
        final orders = controller.orders;
        final filteredOrders = controller.filteredOrders;
        if (orders.isEmpty) {
          return _EmptyOrderHistory();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _OrderHistoryOverview(
                visibleOrderCount: filteredOrders.length,
                totalOrderCount: orders.length,
                totalSales: controller.filteredTotalSales,
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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: filteredOrders.isEmpty
                    ? _EmptyFilterResult(
                        key: const ValueKey('empty-filter'),
                        onClear: controller.clearFilters,
                      )
                    : RefreshIndicator(
                        key: const ValueKey('filtered-list'),
                        onRefresh: controller.loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _OrderHistoryCard(
                                order: order,
                                currencyFormat: currencyFormat,
                                onTap: () =>
                                    Get.to(() => OrderDetailPage(order: order)),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _OrderHistoryOverview extends StatelessWidget {
  const _OrderHistoryOverview({
    required this.visibleOrderCount,
    required this.totalOrderCount,
    required this.totalSales,
    required this.currencyFormat,
    required this.hasActiveFilters,
  });

  final int visibleOrderCount;
  final int totalOrderCount;
  final double totalSales;
  final NumberFormat currencyFormat;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                      hasActiveFilters
                          ? 'Filtered Order Results'
                          : 'Order History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasActiveFilters
                          ? 'Showing $visibleOrderCount of $totalOrderCount orders'
                          : 'Showing $visibleOrderCount orders ready to review',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'FILTERED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OverviewTile(
                  label: 'Orders',
                  value: '$visibleOrderCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewTile(
                  label: 'Sales Total',
                  value: 'MMK ${currencyFormat.format(totalSales)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTile extends StatelessWidget {
  const _OverviewTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.controller});

  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Active Filters',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: controller.clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (controller.invoiceFilter.value.trim().isNotEmpty)
                _FilterChip(
                  label: 'Invoice: ${controller.invoiceFilter.value.trim()}',
                ),
              if (controller.filterStartDate.value != null ||
                  controller.filterEndDate.value != null)
                _FilterChip(
                  label:
                      'Date: ${_formatRange(controller.filterStartDate.value, controller.filterEndDate.value)}',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRange(DateTime? start, DateTime? end) {
    final formatter = DateFormat('dd MMM yyyy');
    if (start != null && end != null) {
      return '${formatter.format(start)} - ${formatter.format(end)}';
    }
    if (start != null) {
      return 'From ${formatter.format(start)}';
    }
    if (end != null) {
      return 'Until ${formatter.format(end)}';
    }
    return '-';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.currencyFormat,
    required this.onTap,
  });

  final Order order;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerLabel = order.customerName?.trim().isNotEmpty == true
        ? order.customerName!.trim()
        : 'Walk-in Customer';
    final phoneLabel = order.customerPhone?.trim().isNotEmpty == true
        ? order.customerPhone!.trim()
        : 'No phone';
    final paidLabel = 'Paid ${currencyFormat.format(order.givenAmount)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.cardColor,
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.invoiceNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(order.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _HistoryStatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.person_outline_rounded,
                      label: customerLabel,
                    ),
                    _MetaPill(icon: Icons.phone_outlined, label: phoneLabel),
                    _MetaPill(icon: Icons.payments_outlined, label: paidLabel),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grand Total',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.70),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MMK ${currencyFormat.format(order.totalPrice)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Receipt',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Unknown date';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    return DateFormat('dd MMM yyyy • hh:mm a').format(parsed);
  }
}

class _EmptyFilterResult extends StatelessWidget {
  const _EmptyFilterResult({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.filter_alt_off_rounded,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No matching orders',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try another invoice number or a different date range.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Clear filters'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryStatusBadge extends StatelessWidget {
  const _HistoryStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();

    Color background;
    Color foreground;

    switch (normalized) {
      case 'completed':
        background = Colors.green.shade100;
        foreground = Colors.green.shade800;
        break;
      case 'pending':
        background = Colors.orange.shade100;
        foreground = Colors.orange.shade800;
        break;
      case 'cancelled':
        background = Colors.red.shade100;
        foreground = Colors.red.shade800;
        break;
      default:
        background = Colors.blueGrey.shade100;
        foreground = Colors.blueGrey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrderHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No orders yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Completed sales will appear here with a receipt-style detail view.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
