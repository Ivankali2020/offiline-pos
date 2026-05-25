class Order {
  final int? id;
  final String invoiceNumber;
  final int sellerId;
  final String? customerName;
  final String? customerPhone;
  final String status;
  final double subTotal;
  final double deliveryFees;
  final double totalPrice;
  final int? paymentId;
  final int? paymentAccountId;
  final double tax;
  final double taxPrice;
  final double givenAmount;
  final double changeAmount;
  final String? note;
  final String? imagePath;
  final String? createdAt;
  final String? updatedAt;

  Order({
    this.id,
    required this.invoiceNumber,
    required this.sellerId,
    this.customerName,
    this.customerPhone,
    required this.status,
    required this.subTotal,
    required this.deliveryFees,
    required this.totalPrice,
    this.paymentId,
    this.paymentAccountId,
    required this.tax,
    required this.taxPrice,
    required this.givenAmount,
    required this.changeAmount,
    this.note,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromMap(Map<String, Object?> map) {
    return Order(
      id: map['id'] as int?,
      invoiceNumber: map['invoice_number'] as String,
      sellerId: map['seller_id'] as int,
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      status: map['status'] as String,
      subTotal: (map['sub_total'] as num).toDouble(),
      deliveryFees: (map['delivery_fees'] as num).toDouble(),
      totalPrice: (map['total_price'] as num).toDouble(),
      paymentId: map['payment_id'] as int?,
      paymentAccountId: map['payment_account_id'] as int?,
      tax: (map['tax'] as num).toDouble(),
      taxPrice: (map['tax_price'] as num).toDouble(),
      givenAmount: (map['given_amount'] as num).toDouble(),
      changeAmount: (map['change_amount'] as num).toDouble(),
      note: map['note'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'seller_id': sellerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'status': status,
      'sub_total': subTotal,
      'delivery_fees': deliveryFees,
      'total_price': totalPrice,
      'payment_id': paymentId,
      'payment_account_id': paymentAccountId,
      'tax': tax,
      'tax_price': taxPrice,
      'given_amount': givenAmount,
      'change_amount': changeAmount,
      'note': note,
      'image_path': imagePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
