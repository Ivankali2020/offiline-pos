class OrderReturnProduct {
  final int? id;
  final int orderReturnId;
  final int orderProductId;
  final int quantity;
  final String? individualReason;
  final String? conditionNotes;
  final double unitRefundAmount;
  final double totalRefundAmount;
  final bool isRestocked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Additional fields for UI display
  final String? productName;
  final String? variantName;

  OrderReturnProduct({
    this.id,
    required this.orderReturnId,
    required this.orderProductId,
    this.quantity = 0,
    this.individualReason,
    this.conditionNotes,
    this.unitRefundAmount = 0.0,
    this.totalRefundAmount = 0.0,
    this.isRestocked = false,
    this.createdAt,
    this.updatedAt,
    this.productName,
    this.variantName,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_return_id': orderReturnId,
      'order_product_id': orderProductId,
      'quantity': quantity,
      'individual_reason': individualReason,
      'condition_notes': conditionNotes,
      'unit_refund_amount': unitRefundAmount,
      'total_refund_amount': totalRefundAmount,
      'is_restocked': isRestocked ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory OrderReturnProduct.fromMap(Map<String, dynamic> map) {
    return OrderReturnProduct(
      id: map['id'],
      orderReturnId: map['order_return_id'],
      orderProductId: map['order_product_id'],
      quantity: map['quantity'] ?? 0,
      individualReason: map['individual_reason'],
      conditionNotes: map['condition_notes'],
      unitRefundAmount: double.tryParse(map['unit_refund_amount'].toString()) ?? 0.0,
      totalRefundAmount: double.tryParse(map['total_refund_amount'].toString()) ?? 0.0,
      isRestocked: map['is_restocked'] == 1,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
      productName: map['product_name'],
      variantName: map['variant_name'],
    );
  }
}
