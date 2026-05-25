class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? createdAt;
  final String? updatedAt;

  Supplier({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromMap(Map<String, Object?> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
