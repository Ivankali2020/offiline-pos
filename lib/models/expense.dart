class Expense {
  final int? id;
  final int categoryId;
  final double amount;
  final String? description;
  final String paymentMethod;
  final String transactionType;
  final String? createdAt;
  final String? updatedAt;
  final String? categoryName;
  final String? categoryIcon;

  Expense({
    this.id,
    required this.categoryId,
    required this.amount,
    this.description,
    required this.paymentMethod,
    this.transactionType = 'expense',
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.categoryIcon,
  });

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int?,
      categoryId:
          (map['expanse_category_id'] ?? map['expense_category_id']) as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
      paymentMethod: (map['payment_method'] as String?) ?? 'Cash',
      transactionType: (map['transaction_type'] as String?) ?? 'expense',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      categoryName: map['category_name'] as String?,
      categoryIcon: map['category_icon'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'expanse_category_id': categoryId,
      'amount': amount,
      'description': description,
      'payment_method': paymentMethod,
      'transaction_type': transactionType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
