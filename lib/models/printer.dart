class Printer {
  final int? id;
  final String name;
  final String? type;
  final String? address;
  final bool isDefault;
  final String? createdAt;
  final String? updatedAt;

  Printer({
    this.id,
    required this.name,
    this.type,
    this.address,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Printer.fromMap(Map<String, Object?> map) {
    return Printer(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String?,
      address: map['address'] as String?,
      isDefault: (map['is_default'] as int?) == 1,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
