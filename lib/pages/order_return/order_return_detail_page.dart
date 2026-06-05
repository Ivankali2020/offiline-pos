import 'package:abpos/controllers/order_return_controller.dart';
import 'package:abpos/models/order_return.dart';
import 'package:abpos/models/order_return_product.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/form/custom_form_sheet.dart';
import 'package:abpos/widgets/form/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderReturnDetailPage extends StatefulWidget {
  const OrderReturnDetailPage({super.key, required this.returnId});

  final int returnId;

  @override
  State<OrderReturnDetailPage> createState() => _OrderReturnDetailPageState();
}

class _OrderReturnDetailPageState extends State<OrderReturnDetailPage> {
  final OrderReturnController _controller = Get.put(OrderReturnController());
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');
  late final Future<OrderReturn?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _controller.getReturnDetail(widget.returnId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'return_detail'.tr,
      appBar: CustomAppBar(
        title: 'return_detail'.tr,
        subtitle: 'return_detail_subtitle'.tr,
        actions: [
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'delete'.tr,
          ),
        ],
      ),
      body: FutureBuilder<OrderReturn?>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final returnData = snapshot.data;
          if (returnData == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'no_data'.tr,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = returnData.returnProducts ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildInfoCard(theme, returnData),
                    const SizedBox(height: 16),
                    _buildProductsCard(theme, products),
                    const SizedBox(height: 16),
                    _buildTotalCard(theme, returnData),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text('back'.tr),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
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
                await _controller.deleteReturn(widget.returnId);
                Get.back(); // close sheet
                Get.back(); // go back from detail
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, OrderReturn returnData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_return_rounded,
                  color: Color(0xFFF43F5E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      returnData.invoiceNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (returnData.createdAt != null)
                      Text(
                        _dateFormat.format(returnData.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(
            label: 'original_invoice'.tr,
            value: returnData.originalInvoiceNumber ?? '-',
          ),
          if (returnData.restockingDecision != null &&
              returnData.restockingDecision!.isNotEmpty)
            _InfoRow(
              label: 'restocking_decision'.tr,
              value: returnData.restockingDecision!,
            ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(
    ThemeData theme,
    List<OrderReturnProduct> products,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'returned_items'.tr,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'no_data'.tr,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey.shade100,
                    ),
                  _ReturnProductTile(
                    product: product,
                    currencyFormat: _currencyFormat,
                  ),
                ],
              );
            }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTotalCard(ThemeData theme, OrderReturn returnData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF43F5E).withValues(alpha: 0.06),
        border: Border.all(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'total_refund'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_currencyFormat.format(returnData.totalRefundAmount)} MMK',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFFF43F5E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnProductTile extends StatelessWidget {
  const _ReturnProductTile({
    required this.product,
    required this.currencyFormat,
  });

  final OrderReturnProduct product;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName ?? 'Unknown',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (product.variantName != null &&
                    product.variantName!.isNotEmpty)
                  Text(
                    product.variantName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${product.quantity} x ${currencyFormat.format(product.unitRefundAmount)} MMK',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                if (product.individualReason != null &&
                    product.individualReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${'reason'.tr}: ${product.individualReason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: product.isRestocked
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      product.isRestocked ? 'restocked'.tr : 'not_restocked'.tr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: product.isRestocked
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${currencyFormat.format(product.totalRefundAmount)} MMK',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF43F5E),
            ),
          ),
        ],
      ),
    );
  }
}
