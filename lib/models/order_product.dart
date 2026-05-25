class OrderProduct {
  final int? id;
  final int orderId;
  final int productId;
  final int? variantId;
  final String? attributes;
  final double price;
  final double discountPrice;
  final double discount;
  final int quantity;
  final double profit;
  final double originalBuyPrice;
  final double originalPrice;
  final double totalRefundedAmount;
  final String? createdAt;
  final String? updatedAt;

  // Joined/Display fields (non-persisted in OrderProduct table directly usually, 
  // but kept here for UI convenience)
  final String? productName;
  final String? variantName;

  OrderProduct({
    this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    this.attributes,
    required this.price,
    required this.discountPrice,
    required this.discount,
    required this.quantity,
    required this.profit,
    required this.originalBuyPrice,
    required this.originalPrice,
    required this.totalRefundedAmount,
    this.createdAt,
    this.updatedAt,
    this.productName,
    this.variantName,
  });

  factory OrderProduct.fromMap(Map<String, Object?> map) {
    return OrderProduct(
      id: map['id'] as int?,
      orderId: map['order_id'] as int,
      productId: map['product_id'] as int,
      variantId: map['variant_id'] as int?,
      attributes: map['attributes'] as String?,
      price: (map['price'] as num).toDouble(),
      discountPrice: (map['discount_price'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      quantity: map['quantity'] as int,
      profit: (map['profit'] as num).toDouble(),
      originalBuyPrice: (map['original_buy_price'] as num).toDouble(),
      originalPrice: (map['original_price'] as num).toDouble(),
      totalRefundedAmount: (map['total_refunded_amount'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      productName: map['product_name'] as String?,
      variantName: map['variant_name'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'variant_id': variantId,
      'attributes': attributes,
      'price': price,
      'discount_price': discountPrice,
      'discount': discount,
      'quantity': quantity,
      'profit': profit,
      'original_buy_price': originalBuyPrice,
      'original_price': originalPrice,
      'total_refunded_amount': totalRefundedAmount,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
