class Variant {
  final int? id;
  final int productId;
  final String? name;
  final String? attributes;
  final String? sku;
  final int stockQuantity;
  final double sellPrice;
  final double buyPrice;
  final String? createdAt;
  final String? updatedAt;

  Variant({
    this.id,
    required this.productId,
    this.name,
    this.attributes,
    this.sku,
    required this.stockQuantity,
    required this.sellPrice,
    required this.buyPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory Variant.fromMap(Map<String, Object?> map) {
    return Variant(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      name: map['name'] as String?,
      attributes: map['attributes'] as String?,
      sku: map['sku'] as String?,
      stockQuantity: map['stock_quantity'] as int,
      sellPrice: (map['sell_price'] as num).toDouble(),
      buyPrice: (map['buy_price'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'attributes': attributes,
      'sku': sku,
      'stock_quantity': stockQuantity,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
