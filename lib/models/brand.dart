class Brand {
  final int? id;
  final int sellerId;
  final String name;
  final String? description;
  final String? createdAt;
  final String? updatedAt;

  Brand({
    this.id,
    required this.sellerId,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Brand.fromMap(Map<String, Object?> map) {
    return Brand(
      id: map['id'] as int?,
      sellerId: map['seller_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
