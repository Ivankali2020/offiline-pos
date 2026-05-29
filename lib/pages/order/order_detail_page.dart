import 'dart:io';
import 'dart:typed_data';

import 'package:abpos/controllers/payment_controller.dart';
import 'package:abpos/controllers/order_controller.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/order_product.dart';
import 'package:abpos/models/settings.dart';
import 'package:abpos/services/receipt_printer_utils.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/thermal_receipt_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.order});

  final Order order;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderController _controller = Get.find<OrderController>();
  final SettingsController _settingsController = Get.find<SettingsController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isPrinting = false;

  late final Future<List<OrderProduct>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = widget.order.id == null
        ? Future.value(const <OrderProduct>[])
        : _controller.getOrderProducts(widget.order.id!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSlip = (widget.order.imagePath ?? '').trim().isNotEmpty;

    return AppScaffold(
      title: 'thermal_receipt'.tr,
      appBar: CustomAppBar(
        title: 'thermal_receipt'.tr,
        subtitle: 'receipt_subtitle'.tr,
        actions: [
            IconButton(
              onPressed: _isPrinting ? null : () => _printReceipt(context),
              icon: _isPrinting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.print_rounded,
                      color: theme.colorScheme.primary,
                    ),
              tooltip: 'print_receipt'.tr,
            ),
            if (hasSlip)
              IconButton(
                onPressed: _showSlipPreview,
                icon: Icon(
                  Icons.receipt_long_rounded,
                  color: theme.colorScheme.primary,
                ),
                tooltip: 'payment_slip'.tr,
              ),
          ],
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.20,
      ),
      body: FutureBuilder<List<OrderProduct>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'unable_to_load_order'.tr,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <OrderProduct>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Obx(() {
                  final settings = _settingsController.settings.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildReceiptCard(context, items, settings),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text('back_to_order_history'.tr),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptCard(
    BuildContext context,
    List<OrderProduct> items,
    Settings? settings,
  ) {
    final theme = Theme.of(context);
    final order = widget.order;
    final storeName = _displayText(settings?.storeName, fallback: 'AB POS');
    final receiptHeader = _displayText(
      settings?.receiptHeader,
      fallback: 'thermal_sales_receipt'.tr,
    );
    final receiptFooter = _displayText(
      settings?.receiptFooter,
      fallback: 'please_come_again'.tr,
    );
    final currencyCode = _displayText(settings?.currencyCode, fallback: 'MMK');
    final receiptPhone = (settings?.receiptPhone ?? '').trim();
    final receiptAddress = (settings?.receiptAddress ?? '').trim();
    final paymentName = _paymentName(order.paymentId);
    final monoBase = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
      letterSpacing: 0.2,
      color: Colors.black87,
      height: 1.35,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  storeName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  receiptHeader,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                if (receiptPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    receiptPhone,
                    textAlign: TextAlign.center,
                    style: monoBase?.copyWith(fontSize: 12),
                  ),
                ],
                if (receiptAddress.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    receiptAddress,
                    textAlign: TextAlign.center,
                    style: monoBase?.copyWith(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(order.createdAt),
                  textAlign: TextAlign.center,
                  style: monoBase?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),
                const _PerforatedDivider(),
                const SizedBox(height: 12),
                _ReceiptLine(
                  label: 'invoice'.tr,
                  value: order.invoiceNumber,
                  textStyle: monoBase,
                ),
                _ReceiptLine(
                  label: 'status'.tr,
                  value: order.status.toUpperCase(),
                  textStyle: monoBase,
                ),
                _ReceiptLine(
                  label: 'customer'.tr,
                  value: _displayText(
                    order.customerName,
                    fallback: 'walk_in_customer'.tr,
                  ),
                  textStyle: monoBase,
                ),
                _ReceiptLine(
                  label: 'phone'.tr,
                  value: _displayText(
                    order.customerPhone,
                    fallback: 'not_provided'.tr,
                  ),
                  textStyle: monoBase,
                ),
                const SizedBox(height: 12),
                const _PerforatedDivider(),
                const SizedBox(height: 10),
                Text(
                  'items'.tr,
                  style: monoBase?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  Text(
                    'no_order_items_found'.tr,
                    style: monoBase,
                    textAlign: TextAlign.center,
                  )
                else
                  ...items.map((item) => _buildItemRow(context, item)),
                const SizedBox(height: 12),
                const _PerforatedDivider(),
                const SizedBox(height: 12),
                _SummaryRow(
                  label: 'subtotal'.tr,
                  value:
                      '$currencyCode ${_currencyFormat.format(order.subTotal)}',
                  textStyle: monoBase,
                ),
                _SummaryRow(
                  label: 'delivery_fee'.tr,
                  value:
                      '$currencyCode ${_currencyFormat.format(order.deliveryFees)}',
                  textStyle: monoBase,
                ),
                _SummaryRow(
                  label: 'tax_rate'.tr.replaceAll('@tax', order.tax.toStringAsFixed(0)),
                  value:
                      '$currencyCode ${_currencyFormat.format(order.taxPrice)}',
                  textStyle: monoBase,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'total_caps'.tr,
                  value:
                      '$currencyCode ${_currencyFormat.format(order.totalPrice)}',
                  isEmphasis: true,
                  textStyle: monoBase,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: 'paid'.tr,
                  value:
                      '$currencyCode ${_currencyFormat.format(order.givenAmount)}',
                  textStyle: monoBase,
                ),
                _SummaryRow(
                  label: 'change'.tr,
                  value:
                      '$currencyCode ${_currencyFormat.format(order.changeAmount)}',
                  textStyle: monoBase,
                  valueColor: Colors.green.shade700,
                ),
                _SummaryRow(
                  label: 'paid_by'.tr,
                  value: paymentName.toUpperCase(),
                  textStyle: monoBase,
                ),
                if ((order.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const _PerforatedDivider(),
                  const SizedBox(height: 12),
                  Text(
                    'note_caps'.tr,
                    style: monoBase?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(order.note!.trim(), style: monoBase),
                ],
                const SizedBox(height: 12),
                const _PerforatedDivider(),
                const SizedBox(height: 12),
                Text(
                  'thank_you_purchase'.tr,
                  textAlign: TextAlign.center,
                  style: monoBase?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  receiptFooter,
                  textAlign: TextAlign.center,
                  style: monoBase?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(BuildContext context, OrderProduct item) {
    final itemTotal = item.price * item.quantity;
    final title = item.productName ?? 'product_id_fallback'.tr.replaceAll('@id', item.productId.toString());
    final subtitleParts = <String>[];

    if ((item.variantName ?? '').trim().isNotEmpty) {
      subtitleParts.add(item.variantName!.trim());
    }
    if (item.attributes != null && item.attributes!.isNotEmpty) {
      final attrStrings = <String>[];
      for (final attr in item.attributes!) {
        if (attr is Map<String, dynamic>) {
          final name = attr['attribute']?.toString() ?? '';
          final val = attr['value'];
          if (name.isNotEmpty) {
            if (val is List && val.isNotEmpty) {
              attrStrings.add('$name: ${val.join(', ')}');
            } else if (val != null) {
              attrStrings.add('$name: $val');
            } else {
              attrStrings.add(name);
            }
          }
        } else {
          attrStrings.add(attr.toString());
        }
      }
      if (attrStrings.isNotEmpty) {
        subtitleParts.add(attrStrings.join(' | '));
      }
    }

    final secondary = subtitleParts.isEmpty
        ? ''
        : ' (${subtitleParts.join(', ')})';
    final descriptor =
        '${item.quantity} x ${_currencyFormat.format(item.price)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title$secondary',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  descriptor,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.black54,
                  ),
                ),
              ),
              Text(
                '${_displayText(_settingsController.settings.value?.currencyCode, fallback: 'MMK')} ${_currencyFormat.format(itemTotal)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayText(String? text, {required String fallback}) {
    final value = text?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  String _paymentName(int? paymentId) {
    if (paymentId == null) return 'unknown'.tr;

    for (final payment in _paymentController.payments) {
      if (payment.id == paymentId) {
        final name = payment.name.trim();
        return name.isEmpty ? 'unknown'.tr : name;
      }
    }

    return 'unknown'.tr;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '-';
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }

    return DateFormat('dd MMM yyyy • hh:mm a').format(parsed);
  }

  // ─── Thermal Print Pipeline ─────────────────────────────────────────

  Future<void> _printReceipt(BuildContext ctx) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final order = widget.order;
      final settings = _settingsController.settings.value;
      final items = await _itemsFuture;

      final currencyCode =
          _displayText(settings?.currencyCode, fallback: 'MMK');

      // ── Build the receipt item list ──
      final receiptItems = items.map((item) {
        final subtitleParts = <String>[];
        if ((item.variantName ?? '').trim().isNotEmpty) {
          subtitleParts.add(item.variantName!.trim());
        }
        if (item.attributes != null && item.attributes!.isNotEmpty) {
          final attrStrings = <String>[];
          for (final attr in item.attributes!) {
            if (attr is Map<String, dynamic>) {
              final name = attr['attribute']?.toString() ?? '';
              final val = attr['value'];
              if (name.isNotEmpty) {
                if (val is List && val.isNotEmpty) {
                  attrStrings.add('$name: ${val.join(', ')}');
                } else if (val != null) {
                  attrStrings.add('$name: $val');
                } else {
                  attrStrings.add(name);
                }
              }
            } else {
              attrStrings.add(attr.toString());
            }
          }
          if (attrStrings.isNotEmpty) {
            subtitleParts.add(attrStrings.join(' | '));
          }
        }

        return ReceiptItem(
          name: item.productName ??
              'product_id_fallback'
                  .tr
                  .replaceAll('@id', item.productId.toString()),
          variant: (item.variantName ?? '').trim().isEmpty
              ? null
              : item.variantName!.trim(),
          attributeSummary: subtitleParts.length > 1
              ? subtitleParts.sublist(1).join(', ')
              : null,
          quantity: item.quantity,
          unitPrice: item.price,
          lineTotal: item.price * item.quantity,
        );
      }).toList();

      // ── Construct the print-only widget ──
      final receiptWidget = ThermalReceiptWidget(
        storeName: _displayText(settings?.storeName, fallback: 'AB POS'),
        receiptHeader: _displayText(
          settings?.receiptHeader,
          fallback: 'thermal_sales_receipt'.tr,
        ),
        receiptFooter: _displayText(
          settings?.receiptFooter,
          fallback: 'please_come_again'.tr,
        ),
        receiptPhone: (settings?.receiptPhone ?? '').trim(),
        receiptAddress: (settings?.receiptAddress ?? '').trim(),
        currencyCode: currencyCode,
        invoiceNumber: order.invoiceNumber,
        status: order.status.toUpperCase(),
        customerName: _displayText(
          order.customerName,
          fallback: 'walk_in_customer'.tr,
        ),
        customerPhone: _displayText(
          order.customerPhone,
          fallback: 'not_provided'.tr,
        ),
        paymentName: _paymentName(order.paymentId).toUpperCase(),
        dateFormatted: _formatDate(order.createdAt),
        items: receiptItems,
        subTotal: _currencyFormat.format(order.subTotal),
        deliveryFees: _currencyFormat.format(order.deliveryFees),
        taxLabel:
            'tax_rate'.tr.replaceAll('@tax', order.tax.toStringAsFixed(0)),
        taxPrice: _currencyFormat.format(order.taxPrice),
        totalPrice: _currencyFormat.format(order.totalPrice),
        givenAmount: _currencyFormat.format(order.givenAmount),
        changeAmount: _currencyFormat.format(order.changeAmount),
        note: order.note,
        // Localized labels
        labelInvoice: 'receipt_label_invoice'.tr,
        labelStatus: 'receipt_label_status'.tr,
        labelCustomer: 'receipt_label_customer'.tr,
        labelPhone: 'receipt_label_phone'.tr,
        labelItems: 'receipt_label_items'.tr,
        labelNoItems: 'receipt_label_no_items'.tr,
        labelSubtotal: 'receipt_label_subtotal'.tr,
        labelDelivery: 'receipt_label_delivery'.tr,
        labelTotal: 'receipt_label_total'.tr,
        labelPaid: 'receipt_label_paid'.tr,
        labelChange: 'receipt_label_change'.tr,
        labelPaidBy: 'receipt_label_paid_by'.tr,
        labelNote: 'receipt_label_note'.tr,
        labelThankYou: 'receipt_label_thank_you'.tr,
      );

      // ── Capture to raw RGBA pixels ──
      final Uint8List imageBytes =
          await _screenshotController.captureFromLongWidget(
        receiptWidget,
        pixelRatio: 1.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes.isEmpty) {
        throw Exception('Screenshot capture returned empty data');
      }

      // ── Compile ESC/POS payload ──
      final payload = await compileReceiptPayload(imageBytes);

      // ── Send over TCP to printer ──
      const printerIp = '192.168.100.130';
      const printerPort = 9100;

      final socket = await Socket.connect(
        printerIp,
        printerPort,
        timeout: const Duration(seconds: 5),
      );
      socket.add(payload);
      await socket.flush();
      await socket.close();

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('print_success'.tr),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      debugPrint('Thermal print error: $e');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('${'print_failed'.tr}: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _showSlipPreview() {
    final imagePath = widget.order.imagePath?.trim();
    if (imagePath == null || imagePath.isEmpty) return;

    Get.dialog(
      barrierColor: Colors.black.withValues(alpha: 0.88),
      Material(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'payment_slip'.tr,
                        style: Theme.of(Get.context!).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.12),
                      ),
                      icon: const Icon(Icons.close, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.fitHeight,
                        errorBuilder: (context, error, stackTrace) {
                          return Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'unable_to_load_slip'.tr,
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({
    required this.label,
    required this.value,
    this.textStyle,
  });

  final String label;
  final String value;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 84, child: Text('$label:', style: textStyle)),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: textStyle),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
    this.valueColor,
    this.textStyle,
  });

  final String label;
  final String value;
  final bool isEmphasis;
  final Color? valueColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = isEmphasis
        ? (this.textStyle ?? theme.textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.w900,
          )
        : (this.textStyle ?? theme.textTheme.bodyLarge)?.copyWith(
            fontWeight: FontWeight.w600,
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        Text(value, style: textStyle?.copyWith(color: valueColor)),
      ],
    );
  }
}

class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 12).floor();
        return Row(
          children: List.generate(
            dashCount,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 2,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
