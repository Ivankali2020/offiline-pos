class Category {
  final int? id;
  final int sellerId;
  final int? parentId;
  final String name;
  final String? description;
  final bool isSubCategory;
  final String? createdAt;
  final String? updatedAt;

  Category({
    this.id,
    required this.sellerId,
    this.parentId,
    required this.name,
    this.description,
    required this.isSubCategory,
    this.createdAt,
    this.updatedAt,
  });

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as int?,
      sellerId: map['seller_id'] as int,
      parentId: map['parent_id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
      isSubCategory: (map['is_sub_category'] as int) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'parent_id': parentId,
      'name': name,
      'description': description,
      'is_sub_category': isSubCategory ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
