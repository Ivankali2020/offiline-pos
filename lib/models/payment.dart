class Payment {
  final int? id;
  final String name;
  final String? note;
  final bool isPublished;
  final String? createdAt;
  final String? updatedAt;

  Payment({
    this.id,
    required this.name,
    this.note,
    required this.isPublished,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int?,
      name: map['name'] as String,
      note: map['note'] as String?,
      isPublished: ((map['is_published'] as num?)?.toInt() ?? 0) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'note': note,
      'is_published': isPublished ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
