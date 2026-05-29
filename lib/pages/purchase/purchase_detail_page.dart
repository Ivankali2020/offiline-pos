import 'dart:io';
import 'dart:typed_data';

import 'package:abpos/controllers/purchase_controller.dart';
import 'package:abpos/controllers/settings_controller.dart';
import 'package:abpos/models/purchase.dart';
import 'package:abpos/models/purchase_product.dart';
import 'package:abpos/models/settings.dart';
import 'package:abpos/services/receipt_printer_utils.dart';
import 'package:abpos/widgets/app_scaffold.dart';
import 'package:abpos/widgets/custom_app_bar.dart';
import 'package:abpos/widgets/thermal_receipt_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class PurchaseDetailPage extends StatefulWidget {
  const PurchaseDetailPage({super.key, required this.purchase});

  final Purchase purchase;

  @override
  State<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends State<PurchaseDetailPage> {
  final PurchaseController _controller = Get.find<PurchaseController>();
  final SettingsController _settingsController = Get.find<SettingsController>();
  final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isPrinting = false;

  late Purchase _purchase;
  late Future<List<PurchaseProduct>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _purchase = widget.purchase;
    _itemsFuture = _purchase.id == null
        ? Future.value(const <PurchaseProduct>[])
        : _controller.getPurchaseProducts(_purchase.id!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'purchase_receipt'.tr,
      appBar: CustomAppBar(
        title: 'purchase_receipt'.tr,
        subtitle: 'purchase_receipt_subtitle'.tr,
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
        ],
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.20,
      ),
      body: FutureBuilder<List<PurchaseProduct>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('unable_to_load_purchase_detail'.tr));
          }

          final items = snapshot.data ?? const <PurchaseProduct>[];
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
                      if (_purchase.status.trim().toLowerCase() !=
                          'completed') ...[
                        ElevatedButton.icon(
                          onPressed: _completePurchase,
                          icon: const Icon(Icons.inventory_rounded),
                          label: Text('mark_completed_import_stock'.tr),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildReceiptCard(context, items, settings),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text('back_to_purchase_history'.tr),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
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

  Future<void> _completePurchase() async {
    final purchaseId = _purchase.id;
    if (purchaseId == null) return;
    await _controller.completePurchase(purchaseId);
    final reloaded = await _controller.reloadPurchase(purchaseId);
    if (!mounted) return;
    setState(() {
      if (reloaded != null) {
        _purchase = reloaded;
      }
    });
    Get.snackbar('completed'.tr, 'stock_imported_success'.tr);
  }

  Widget _buildReceiptCard(
    BuildContext context,
    List<PurchaseProduct> items,
    Settings? settings,
  ) {
    final theme = Theme.of(context);
    final storeName = _displayText(settings?.storeName, fallback: 'AB POS');
    final header = _displayText(
      settings?.receiptHeader,
      fallback: 'PURCHASE RECEIPT',
    );
    final footer = _displayText(
      settings?.receiptFooter,
      fallback: 'stock_intake_record_saved'.tr,
    );
    final currencyCode = _displayText(settings?.currencyCode, fallback: 'MMK');
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
      child: Padding(
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
              header,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Colors.black54,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(_purchase.createdAt),
              textAlign: TextAlign.center,
              style: monoBase?.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const _PerforatedDivider(),
            const SizedBox(height: 12),
            _ReceiptLine(
              label: 'invoice'.tr,
              value: _purchase.invoiceNumber,
              textStyle: monoBase,
            ),
            _ReceiptLine(
              label: 'status'.tr,
              value: _purchase.status.toUpperCase(),
              textStyle: monoBase,
            ),
            _ReceiptLine(
              label: 'paid'.tr,
              value:
                  '$currencyCode ${_currencyFormat.format(_purchase.paidAmount)}',
              textStyle: monoBase,
            ),
            _ReceiptLine(
              label: 'due'.tr,
              value:
                  '$currencyCode ${_currencyFormat.format(_purchase.dueAmount)}',
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
              Text('no_purchase_items_found'.tr, style: monoBase)
            else
              ...items.map(_buildItemRow),
            const SizedBox(height: 12),
            const _PerforatedDivider(),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'total_caps'.tr,
              value:
                  '$currencyCode ${_currencyFormat.format(_purchase.totalAmount)}',
              isEmphasis: true,
              textStyle: monoBase,
            ),
            if ((_purchase.note ?? '').trim().isNotEmpty) ...[
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
              Text(_purchase.note!.trim(), style: monoBase),
            ],
            const SizedBox(height: 12),
            const _PerforatedDivider(),
            const SizedBox(height: 12),
            Text(
              _purchase.status.trim().toLowerCase() == 'completed'
                  ? 'stock_has_been_imported'.tr
                  : 'complete_this_receipt_to_import_stock'.tr,
              textAlign: TextAlign.center,
              style: monoBase?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              footer,
              textAlign: TextAlign.center,
              style: monoBase?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(PurchaseProduct item) {
    final title = item.productName ?? 'Product #${item.productId}';
    final variant = (item.variantName ?? '').trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            variant.isEmpty ? title : '$title ($variant)',
            style: const TextStyle(
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
                  '${item.quantity} x ${_currencyFormat.format(item.costPrice)}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                _currencyFormat.format(item.totalCost),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _displayText(String? value, {required String fallback}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Unknown date';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd MMM yyyy • hh:mm a').format(parsed);
  }

  // ─── Thermal Print Pipeline ─────────────────────────────────────────

  Future<void> _printReceipt(BuildContext ctx) async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);

    try {
      final purchase = _purchase;
      final settings = _settingsController.settings.value;
      final items = await _itemsFuture;

      final currencyCode =
          _displayText(settings?.currencyCode, fallback: 'MMK');

      // ── Build the receipt item list ──
      final receiptItems = items.map((item) {
        final title =
            item.productName ?? 'Product #${item.productId}';
        return ReceiptItem(
          name: title,
          variant: (item.variantName ?? '').trim().isEmpty
              ? null
              : item.variantName!.trim(),
          quantity: item.quantity,
          unitPrice: item.costPrice,
          lineTotal: item.totalCost,
        );
      }).toList();

      // ── Construct the print-only widget ──
      // Purchase receipts reuse ThermalReceiptWidget but repurpose
      // some fields: subtotal/delivery/tax become paid/due/-, and
      // change/paidBy are hidden by passing empty strings.
      final receiptWidget = ThermalReceiptWidget(
        storeName: _displayText(settings?.storeName, fallback: 'AB POS'),
        receiptHeader: _displayText(
          settings?.receiptHeader,
          fallback: 'purchase_receipt'.tr,
        ),
        receiptFooter: _displayText(
          settings?.receiptFooter,
          fallback: 'stock_intake_record_saved'.tr,
        ),
        receiptPhone: (settings?.receiptPhone ?? '').trim(),
        receiptAddress: (settings?.receiptAddress ?? '').trim(),
        currencyCode: currencyCode,
        invoiceNumber: purchase.invoiceNumber,
        status: purchase.status.toUpperCase(),
        customerName: '',
        customerPhone: '',
        paymentName: '',
        dateFormatted: _formatDate(purchase.createdAt),
        items: receiptItems,
        subTotal: _currencyFormat.format(purchase.totalAmount),
        deliveryFees: _currencyFormat.format(purchase.paidAmount),
        taxLabel: 'receipt_label_due'.tr,
        taxPrice: _currencyFormat.format(purchase.dueAmount),
        totalPrice: _currencyFormat.format(purchase.totalAmount),
        givenAmount: _currencyFormat.format(purchase.paidAmount),
        changeAmount: _currencyFormat.format(purchase.dueAmount),
        note: purchase.note,
        // Localized labels
        labelInvoice: 'receipt_label_invoice'.tr,
        labelStatus: 'receipt_label_status'.tr,
        labelCustomer: 'receipt_label_customer'.tr,
        labelPhone: 'receipt_label_phone'.tr,
        labelItems: 'receipt_label_items'.tr,
        labelNoItems: 'receipt_label_no_items'.tr,
        labelSubtotal: 'receipt_label_total'.tr,
        labelDelivery: 'receipt_label_paid'.tr,
        labelTotal: 'receipt_label_total'.tr,
        labelPaid: 'receipt_label_paid'.tr,
        labelChange: 'receipt_label_due'.tr,
        labelPaidBy: '',
        labelNote: 'receipt_label_note'.tr,
        labelThankYou: purchase.status.trim().toLowerCase() == 'completed'
            ? 'stock_has_been_imported'.tr
            : 'complete_this_receipt_to_import_stock'.tr,
      );

      // ── Capture to PNG ──
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textStyle)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: textStyle?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
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
    this.textStyle,
  });

  final String label;
  final String value;
  final bool isEmphasis;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (textStyle ?? const TextStyle()).copyWith(
      fontWeight: isEmphasis ? FontWeight.w900 : FontWeight.w700,
      fontSize: isEmphasis ? 15 : textStyle?.fontSize,
      color: isEmphasis ? Colors.black : textStyle?.color,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: effectiveStyle)),
          const SizedBox(width: 12),
          Text(value, style: effectiveStyle),
        ],
      ),
    );
  }
}

class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(width: 4, height: 1.2, color: Colors.black26),
          ),
        );
      },
    );
  }
}
