class ExpenseCategory {
  final int? id;
  final String name;
  final String? icon;
  final String? createdAt;
  final String? updatedAt;

  ExpenseCategory({
    this.id,
    required this.name,
    this.icon,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseCategory.fromMap(Map<String, Object?> map) {
    return ExpenseCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
