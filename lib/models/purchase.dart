class Purchase {
  final int? id;
  final String invoiceNumber;
  final int sellerId;
  final int? supplierId;
  final double totalAmount;
  final double paidAmount;
  final double dueAmount;
  final String status;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  Purchase({
    this.id,
    required this.invoiceNumber,
    required this.sellerId,
    this.supplierId,
    required this.totalAmount,
    required this.paidAmount,
    required this.dueAmount,
    required this.status,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory Purchase.fromMap(Map<String, Object?> map) {
    return Purchase(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      sellerId: map['seller_id'] as int,
      supplierId: map['supplier_id'] as int?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      dueAmount: (map['due_amount'] as num).toDouble(),
      status: map['status'] as String,
      note: map['note'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'seller_id': sellerId,
      'supplier_id': supplierId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'status': status,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
