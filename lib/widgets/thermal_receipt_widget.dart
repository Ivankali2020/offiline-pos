import 'package:flutter/material.dart';

/// Data class representing a single line item on the printed receipt.
class ReceiptItem {
  final String name;
  final String? variant;
  final String? attributeSummary;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const ReceiptItem({
    required this.name,
    this.variant,
    this.attributeSummary,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}

/// A stateless widget that renders a receipt layout at exactly 576 logical
/// pixels wide — the native dot-width of an 80 mm thermal printer at 203 DPI.
///
/// **Design rules enforced:**
/// - Background: `Colors.white` — no transparency, no grey.
/// - All text: `Colors.black` — never `black87`, `black54`, or any alpha.
/// - No Material chrome: no `Card`, `ElevatedButton`, `BoxShadow`,
///   `borderRadius`, or `Opacity` widgets.
/// - Monospace font throughout for pixel-deterministic column alignment.
/// - `Row` + `MainAxisAlignment.spaceBetween` for all key–value pairs.
/// - Product names inside `Expanded` with `TextOverflow.ellipsis` + `maxLines`.
class ThermalReceiptWidget extends StatelessWidget {
  const ThermalReceiptWidget({
    super.key,
    required this.storeName,
    required this.receiptHeader,
    required this.receiptFooter,
    required this.receiptPhone,
    required this.receiptAddress,
    required this.currencyCode,
    required this.invoiceNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.paymentName,
    required this.dateFormatted,
    required this.items,
    required this.subTotal,
    required this.deliveryFees,
    required this.taxLabel,
    required this.taxPrice,
    required this.totalPrice,
    required this.givenAmount,
    required this.changeAmount,
    this.note,
    // Localized labels
    required this.labelInvoice,
    required this.labelStatus,
    required this.labelCustomer,
    required this.labelPhone,
    required this.labelItems,
    required this.labelNoItems,
    required this.labelSubtotal,
    required this.labelDelivery,
    required this.labelTotal,
    required this.labelPaid,
    required this.labelChange,
    required this.labelPaidBy,
    required this.labelNote,
    required this.labelThankYou,
  });

  final String storeName;
  final String receiptHeader;
  final String receiptFooter;
  final String receiptPhone;
  final String receiptAddress;
  final String currencyCode;
  final String invoiceNumber;
  final String status;
  final String customerName;
  final String customerPhone;
  final String paymentName;
  final String dateFormatted;
  final List<ReceiptItem> items;
  final String subTotal;
  final String deliveryFees;
  final String taxLabel;
  final String taxPrice;
  final String totalPrice;
  final String givenAmount;
  final String changeAmount;
  final String? note;

  // Localized labels
  final String labelInvoice;
  final String labelStatus;
  final String labelCustomer;
  final String labelPhone;
  final String labelItems;
  final String labelNoItems;
  final String labelSubtotal;
  final String labelDelivery;
  final String labelTotal;
  final String labelPaid;
  final String labelChange;
  final String labelPaidBy;
  final String labelNote;
  final String labelThankYou;

  // ─── Text styles ──────────────────────────────────────────────────────
  static const _base = TextStyle(
    fontFamily: 'monospace',
    fontSize: 22,
    color: Colors.black,
    height: 1.3,
    decoration: TextDecoration.none,
    letterSpacing: 0,
  );

  static final _storeTitle = _base.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.0,
  );

  static final _sectionHeader = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  static final _headerSub = _base.copyWith(fontSize: 20);

  static final _itemName = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );

  static final _itemDetail = _base.copyWith(fontSize: 20);

  static final _totalLabel = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w900,
  );

  static final _footerStyle = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  // ─── Divider ──────────────────────────────────────────────────────────
  static const String _dash = '- ';
  static final String _dividerText = _dash * 48;

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        _dividerText,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: _base.copyWith(height: 1.0),
      ),
    );
  }

  // ─── Reusable row builders ────────────────────────────────────────────
  Widget _keyValueRow(String label, String value, {TextStyle? style}) {
    final ts = style ?? _base;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: ts),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool emphasis = false}) {
    final ts = emphasis ? _totalLabel : _base;
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ts),
          Text(value, style: ts),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 576.0,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Store header ──
            _centeredText(storeName, _storeTitle),
            const SizedBox(height: 2),
            _centeredText(receiptHeader, _headerSub),

            if (receiptPhone.isNotEmpty) ...[
              const SizedBox(height: 1),
              _centeredText(receiptPhone, _headerSub),
            ],
            if (receiptAddress.isNotEmpty) ...[
              const SizedBox(height: 1),
              _centeredText(receiptAddress, _headerSub),
            ],

            const SizedBox(height: 1),
            _centeredText(dateFormatted, _headerSub),

            // ── Order metadata ──
            _divider(),
            _keyValueRow(labelInvoice, invoiceNumber),
            _keyValueRow(labelStatus, status),
            _keyValueRow(labelCustomer, customerName),
            _keyValueRow(labelPhone, customerPhone),

            // ── Line items ──
            _divider(),
            Text(labelItems, style: _sectionHeader),
            const SizedBox(height: 4),

            if (items.isEmpty)
              _centeredText(labelNoItems, _base)
            else
              ...items.map(_buildItemTile),

            // ── Totals ──
            _divider(),
            _summaryRow(labelSubtotal, '$currencyCode $subTotal'),
            _summaryRow(labelDelivery, '$currencyCode $deliveryFees'),
            _summaryRow(taxLabel, '$currencyCode $taxPrice'),
            const SizedBox(height: 2),
            _summaryRow(labelTotal, '$currencyCode $totalPrice', emphasis: true),
            const SizedBox(height: 2),
            _summaryRow(labelPaid, '$currencyCode $givenAmount'),
            _summaryRow(labelChange, '$currencyCode $changeAmount'),
            _summaryRow(labelPaidBy, paymentName),

            // ── Note (optional) ──
            if (note != null && note!.trim().isNotEmpty) ...[
              _divider(),
              Text(labelNote, style: _sectionHeader),
              const SizedBox(height: 2),
              Text(note!.trim(), style: _base),
            ],

            // ── Footer ──
            _divider(),
            _centeredText(labelThankYou, _footerStyle),
            const SizedBox(height: 2),
            _centeredText(receiptFooter, _headerSub),
          ],
        ),
      ),
    );
  }

  // ─── Item tile ────────────────────────────────────────────────────────
  Widget _buildItemTile(ReceiptItem item) {
    final detail = <String>[
      if (item.variant != null && item.variant!.isNotEmpty) item.variant!,
      if (item.attributeSummary != null && item.attributeSummary!.isNotEmpty)
        item.attributeSummary!,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: name (ellipsized) + line total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _itemName,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currencyCode ${_fmt(item.lineTotal)}',
                style: _itemName,
              ),
            ],
          ),

          // Row 2: variant / attributes (if any)
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _itemDetail,
              ),
            ),

          // Row 3: quantity × unit price
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              '${item.quantity} x ${_fmt(item.unitPrice)}',
              style: _itemDetail,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  Widget _centeredText(String text, TextStyle style) {
    return Text(text, textAlign: TextAlign.center, style: style);
  }

  static String _fmt(double v) {
    // Thousands-separated, no decimals — matches the app's NumberFormat('#,##0')
    final parts = <String>[];
    int n = v.round().abs();
    if (n == 0) return '0';
    while (n > 0) {
      final rem = n % 1000;
      n = n ~/ 1000;
      parts.add(n > 0 ? rem.toString().padLeft(3, '0') : rem.toString());
    }
    return (v < 0 ? '-' : '') + parts.reversed.join(',');
  }
}
