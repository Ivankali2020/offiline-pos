class PurchaseProduct {
  final int? id;
  final int purchaseId;
  final int productId;
  final int? variantId;
  final int quantity;
  final double costPrice;
  final double? sellPrice;
  final double totalCost;
  final String? createdAt;
  final String? updatedAt;
  final String? productName;
  final String? variantName;

  PurchaseProduct({
    this.id,
    required this.purchaseId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.costPrice,
    this.sellPrice,
    required this.totalCost,
    this.createdAt,
    this.updatedAt,
    this.productName,
    this.variantName,
  });

  factory PurchaseProduct.fromMap(Map<String, Object?> map) {
    return PurchaseProduct(
      id: map['id'] as int?,
      purchaseId: map['purchase_id'] as int,
      productId: map['product_id'] as int,
      variantId: map['variant_id'] as int?,
      quantity: map['quantity'] as int,
      costPrice: (map['cost_price'] as num).toDouble(),
      sellPrice: (map['sell_price'] as num?)?.toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      productName: map['product_name'] as String?,
      variantName: map['variant_name'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      'cost_price': costPrice,
      'sell_price': sellPrice ?? 0,
      'total_cost': totalCost,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
