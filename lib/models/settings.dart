class Settings {
  final int? id;
  final int? sellerId;
  final String? storeName;
  final String? receiptPhone;
  final String? receiptAddress;
  final String currencyCode;
  final String currencySymbol;
  final String? receiptHeader;
  final String? receiptFooter;
  final int? defaultPaymentId;
  final double taxRate;
  final String? createdAt;
  final String? updatedAt;

  Settings({
    this.id,
    this.sellerId,
    this.storeName,
    this.receiptPhone,
    this.receiptAddress,
    required this.currencyCode,
    required this.currencySymbol,
    this.receiptHeader,
    this.receiptFooter,
    this.defaultPaymentId,
    required this.taxRate,
    this.createdAt,
    this.updatedAt,
  });

  factory Settings.fromMap(Map<String, Object?> map) {
    return Settings(
      id: map['id'] as int?,
      sellerId: map['seller_id'] as int?,
      storeName: map['store_name'] as String?,
      receiptPhone: map['receipt_phone'] as String?,
      receiptAddress: map['receipt_address'] as String?,
      currencyCode: map['currency_code'] as String,
      currencySymbol: map['currency_symbol'] as String,
      receiptHeader: map['receipt_header'] as String?,
      receiptFooter: map['receipt_footer'] as String?,
      defaultPaymentId: map['default_payment_id'] as int?,
      taxRate: (map['tax_rate'] as num).toDouble(),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'seller_id': sellerId,
      'store_name': storeName,
      'receipt_phone': receiptPhone,
      'receipt_address': receiptAddress,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'receipt_header': receiptHeader,
      'receipt_footer': receiptFooter,
      'default_payment_id': defaultPaymentId,
      'tax_rate': taxRate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
