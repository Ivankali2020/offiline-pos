class Product {
  final int? id;
  final int sellerId;
  final int? categoryId;
  final int? brandId;
  final int? supplierId;
  final String? sku;
  final String name;
  final String? description;
  final int stockQuantity;
  final int stockThreshold;
  final double sellPrice;
  final double buyPrice;
  final bool hasVariant;
  final bool isActive;
  final String? expiredDate;
  final String? createdAt;
  final String? updatedAt;

  // Joined fields
  final String? categoryName;
  final String? brandName;

  Product({
    this.id,
    required this.sellerId,
    this.categoryId,
    this.brandId,
    this.supplierId,
    this.sku,
    required this.name,
    this.description,
    required this.stockQuantity,
    required this.stockThreshold,
    required this.sellPrice,
    required this.buyPrice,
    required this.hasVariant,
    required this.isActive,
    this.expiredDate,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.brandName,
  });

  factory Product.fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as int?,
      sellerId: map['seller_id'] as int,
      categoryId: map['category_id'] as int?,
      brandId: map['brand_id'] as int?,
      supplierId: map['supplier_id'] as int?,
      sku: map['sku'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      stockQuantity: map['stock_quantity'] as int,
      stockThreshold: map['stock_threshold'] as int,
      sellPrice: (map['sell_price'] as num).toDouble(),
      buyPrice: (map['buy_price'] as num).toDouble(),
      hasVariant: (map['has_variant'] as int?) == 1,
      isActive: (map['is_active'] as int) == 1,
      expiredDate: map['expired_date'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      categoryName: map['category_name'] as String?,
      brandName: map['brand_name'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'brand_id': brandId,
      'supplier_id': supplierId,
      'sku': sku,
      'name': name,
      'description': description,
      'stock_quantity': stockQuantity,
      'stock_threshold': stockThreshold,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'has_variant': hasVariant ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'expired_date': expiredDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
