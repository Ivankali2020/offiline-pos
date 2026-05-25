class ProductAttributeSelection {
  final int? id;
  final int productId;
  final int attributeId;
  final int attributeValueId;
  final String? attributeName;
  final String? attributeType;
  final String? value;
  final String? colorCode;
  final String? createdAt;
  final String? updatedAt;

  ProductAttributeSelection({
    this.id,
    required this.productId,
    required this.attributeId,
    required this.attributeValueId,
    this.attributeName,
    this.attributeType,
    this.value,
    this.colorCode,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductAttributeSelection.fromMap(Map<String, Object?> map) {
    return ProductAttributeSelection(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      attributeId: map['attribute_id'] as int,
      attributeValueId: map['attribute_value_id'] as int,
      attributeName: map['attribute_name'] as String?,
      attributeType: map['attribute_type'] as String?,
      value: map['value'] as String?,
      colorCode: map['color_code'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'attribute_id': attributeId,
      'attribute_value_id': attributeValueId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
