class AttributeValue {
  final int? id;
  final int attributeId;
  final String value;
  final String? colorCode;
  final String? createdAt;
  final String? updatedAt;

  AttributeValue({
    this.id,
    required this.attributeId,
    required this.value,
    this.colorCode,
    this.createdAt,
    this.updatedAt,
  });

  factory AttributeValue.fromMap(Map<String, Object?> map) {
    return AttributeValue(
      id: map['id'] as int?,
      attributeId: map['attribute_id'] as int,
      value: map['value'] as String,
      colorCode: map['color_code'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'attribute_id': attributeId,
      'value': value,
      'color_code': colorCode,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
