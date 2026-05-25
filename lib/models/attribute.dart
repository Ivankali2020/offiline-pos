class Attribute {
  final int? id;
  final int sellerId;
  final String name;
  final String type;
  final String? createdAt;
  final String? updatedAt;

  Attribute({
    this.id,
    required this.sellerId,
    required this.name,
    required this.type,
    this.createdAt,
    this.updatedAt,
  });

  factory Attribute.fromMap(Map<String, Object?> map) {
    return Attribute(
      id: map['id'] as int?,
      sellerId: map['seller_id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'type': type,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
