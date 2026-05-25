class PaymentAccount {
  final int? id;
  final int paymentId;
  final String number;
  final String name;
  final String? createdAt;
  final String? updatedAt;
  final String? paymentName;

  PaymentAccount({
    this.id,
    required this.paymentId,
    required this.number,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.paymentName,
  });

  factory PaymentAccount.fromMap(Map<String, Object?> map) {
    return PaymentAccount(
      id: map['id'] as int?,
      paymentId: map['payment_id'] as int,
      number: map['number'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      paymentName: map['payment_name'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'payment_id': paymentId,
      'number': number,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
