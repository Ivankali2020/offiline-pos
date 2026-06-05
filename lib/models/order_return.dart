import 'package:abpos/models/order_return_product.dart';

class OrderReturn {
  final int? id;
  final String invoiceNumber;
  final int orderId;
  final int sellerId;
  final double totalRefundAmount;
  final String? restockingDecision;
  final String? paymentSlip;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderReturnProduct>? returnProducts;
  
  // For UI display
  final String? originalInvoiceNumber;

  OrderReturn({
    this.id,
    required this.invoiceNumber,
    required this.orderId,
    required this.sellerId,
    this.totalRefundAmount = 0.0,
    this.restockingDecision,
    this.paymentSlip,
    this.createdAt,
    this.updatedAt,
    this.returnProducts,
    this.originalInvoiceNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'order_id': orderId,
      'seller_id': sellerId,
      'total_refund_amount': totalRefundAmount,
      'restocking_decision': restockingDecision,
      'payment_slip': paymentSlip,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory OrderReturn.fromMap(Map<String, dynamic> map, {List<OrderReturnProduct>? returnProducts}) {
    return OrderReturn(
      id: map['id'],
      invoiceNumber: map['invoice_number'],
      orderId: map['order_id'],
      sellerId: map['seller_id'],
      totalRefundAmount: double.tryParse(map['total_refund_amount'].toString()) ?? 0.0,
      restockingDecision: map['restocking_decision'],
      paymentSlip: map['payment_slip'],
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      originalInvoiceNumber: map['original_invoice_number'],
      returnProducts: returnProducts,
    );
  }
}
