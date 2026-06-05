import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/controllers/order_return_controller.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/order_return.dart';
import 'package:abpos/pages/order_return/order_return_detail_page.dart';
import 'package:abpos/pages/order_return/order_return_filter_bottom_sheet.dart';
import 'package:abpos/routes/app_routes.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/barcode_scanner_button.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OrderReturnPage extends StatefulWidget {
  const OrderReturnPage({super.key});

  @override
  State<OrderReturnPage> createState() => _OrderReturnPageState();
}

class _OrderReturnPageState extends State<OrderReturnPage> {
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OrderReturnController());
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'order_returns'.tr,
      appBar: CustomAppBar(
        title: 'order_returns'.tr,
        subtitle: 'manage_order_returns'.tr,
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'filter_returns'.tr,
                    onPressed: () =>
                        OrderReturnFilterBottomSheet.show(context, controller),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: controller.activeFilterCount > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
                          color: theme.colorScheme.error,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showOrderPicker(context),
        icon: const Icon(LucideIcons.plus),
        label: Text('create_return'.tr),
      ),
      body: Obx(() {
        final allReturns = controller.returns;
        final filteredReturns = controller.filteredReturns;

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (allReturns.isEmpty) {
          return _EmptyReturns();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: _ReturnsOverview(
                visibleCount: filteredReturns.length,
                totalCount: allReturns.length,
                totalRefunds: controller.filteredTotalRefunds,
                currencyFormat: _numberFormat,
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
                child: filteredReturns.isEmpty
                    ? _EmptyFilterResult(
                        key: const ValueKey('empty-filter'),
                        onClear: controller.clearFilters,
                      )
                    : RefreshIndicator(
                        key: const ValueKey('filtered-list'),
                        onRefresh: controller.loadReturns,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: filteredReturns.length,
                          itemBuilder: (context, index) {
                            final returnItem = filteredReturns[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _ReturnCard(
                                returnItem: returnItem,
                                currencyFormat: _numberFormat,
                                onTap: () => Get.to(
                                  () => OrderReturnDetailPage(
                                    returnId: returnItem.id!,
                                  ),
                                ),
                                onDelete: () => _confirmDelete(
                                  context,
                                  controller,
                                  returnItem.id!,
                                ),
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

  void _showOrderPicker(BuildContext context) {
    final orderController = Get.find<OrderController>();
    final theme = Theme.of(context);
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'select_order'.tr,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'select_order_subtitle'.tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: searchController,
                onChanged: (v) => searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'search_orders'.tr,
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BarcodeScannerButton(
                        onScan: (code) {
                          searchController.text = code;
                          searchQuery.value = code;
                        },
                      ),
                      Obx(
                        () => searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  searchQuery.value = '';
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final query = searchQuery.value.trim().toLowerCase();
                final orders = orderController.orders.where((o) {
                  if (query.isEmpty) return true;
                  return o.invoiceNumber.toLowerCase().contains(query) ||
                      (o.customerName ?? '').toLowerCase().contains(query);
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      'no_data'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderPickerCard(
                      order: order,
                      numberFormat: _numberFormat,
                      onTap: () => _onOrderSelected(order),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onOrderSelected(Order order) async {
    Get.back();
    final orderController = Get.find<OrderController>();
    final products = await orderController.getOrderProducts(order.id!);
    Get.toNamed(
      AppRoutes.orderReturnCreate,
      arguments: {'order': order, 'products': products},
    );
  }

  void _confirmDelete(
    BuildContext context,
    OrderReturnController controller,
    int id,
  ) {
    Get.bottomSheet(
      isScrollControlled: true,
      CustomFormSheet(
        title: 'delete'.tr,
        subtitle: 'delete_return_subtitle'.tr,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormActionButtons(
              confirmLabel: 'delete'.tr,
              isDestructive: true,
              onConfirm: () async {
                await controller.deleteReturn(id);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overview Card ───────────────────────────────────────────────────────

class _ReturnsOverview extends StatelessWidget {
  const _ReturnsOverview({
    required this.visibleCount,
    required this.totalCount,
    required this.totalRefunds,
    required this.currencyFormat,
    required this.hasActiveFilters,
  });

  final int visibleCount;
  final int totalCount;
  final double totalRefunds;
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
            const Color(0xFFF43F5E),
            const Color(0xFFF43F5E).withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF43F5E).withValues(alpha: 0.24),
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
                          ? 'filtered_return_results'.tr
                          : 'order_returns'.tr,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasActiveFilters
                          ? 'showing_filtered_returns'.tr
                                .replaceAll('@visible', '$visibleCount')
                                .replaceAll('@total', '$totalCount')
                          : 'showing_returns_ready'.tr.replaceAll(
                              '@visible',
                              '$visibleCount',
                            ),
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
                  child: Text(
                    'filtered_badge'.tr,
                    style: const TextStyle(
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
                  label: 'returns'.tr,
                  value: '$visibleCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewTile(
                  label: 'total_refund'.tr,
                  value: 'MMK ${currencyFormat.format(totalRefunds)}',
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

// ── Active Filter Bar ───────────────────────────────────────────────────

class _ActiveFilterBar extends StatelessWidget {
  const _ActiveFilterBar({required this.controller});

  final OrderReturnController controller;

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
              Expanded(
                child: Text(
                  'active_filters'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: controller.clearFilters,
                child: Text('clear_all'.tr),
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
                  label: 'filter_invoice'.tr.replaceAll(
                    '@value',
                    controller.invoiceFilter.value.trim(),
                  ),
                ),
              if (controller.filterStartDate.value != null ||
                  controller.filterEndDate.value != null)
                _FilterChip(
                  label: 'filter_date'.tr.replaceAll(
                    '@range',
                    _formatRange(
                      controller.filterStartDate.value,
                      controller.filterEndDate.value,
                    ),
                  ),
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
      return 'from_date'.tr.replaceAll('@start', formatter.format(start));
    }
    if (end != null) {
      return 'until_date'.tr.replaceAll('@end', formatter.format(end));
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

// ── Return Card ─────────────────────────────────────────────────────────

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({
    required this.returnItem,
    required this.currencyFormat,
    required this.onTap,
    required this.onDelete,
  });

  final OrderReturn returnItem;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.cardColor,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.12),
            ),
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
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.assignment_return_rounded,
                        color: Color(0xFFF43F5E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            returnItem.invoiceNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(returnItem.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.receipt_long_rounded,
                      label:
                          '${'original_invoice'.tr}: ${returnItem.originalInvoiceNumber ?? '-'}',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF43F5E).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'total_refund'.tr,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.70),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MMK ${currencyFormat.format(returnItem.totalRefundAmount)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF43F5E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 20),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                        ),
                        tooltip: 'delete'.tr,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'details'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'unknown_date'.tr;
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
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
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty States ────────────────────────────────────────────────────────

class _EmptyReturns extends StatelessWidget {
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
                color: const Color(0xFFF43F5E).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_return_rounded,
                size: 40,
                color: Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'no_returns_yet'.tr,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'no_returns_subtitle'.tr,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withValues(
                  alpha: 0.75,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                'no_matching_returns'.tr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'try_another_return_filter'.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.textTheme.bodyLarge?.color?.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text('clear_filters'.tr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Order Picker Card ───────────────────────────────────────────────────

class _OrderPickerCard extends StatelessWidget {
  const _OrderPickerCard({
    required this.order,
    required this.numberFormat,
    required this.onTap,
  });

  final Order order;
  final NumberFormat numberFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = order.createdAt != null
        ? DateFormat(
            'dd MMM yyyy, HH:mm',
          ).format(DateTime.parse(order.createdAt!))
        : '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.invoiceNumber,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (order.customerName != null &&
                      order.customerName!.isNotEmpty)
                    Text(
                      order.customerName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (dateStr.isNotEmpty)
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${numberFormat.format(order.totalPrice)} MMK',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
