class ImportLog {
  final int? id;
  final String importType;
  final String? targetTable;
  final String fileName;
  final String filePath;
  final String importer;
  final String status;
  final int processedRows;
  final int totalRows;
  final int successfulRows;
  final int failedRows;
  final String? errorMessage;
  final int? sellerId;
  final String? completedAt;
  final String? createdAt;
  final String? updatedAt;

  ImportLog({
    this.id,
    required this.importType,
    this.targetTable,
    required this.fileName,
    required this.filePath,
    required this.importer,
    required this.status,
    required this.processedRows,
    required this.totalRows,
    required this.successfulRows,
    required this.failedRows,
    this.errorMessage,
    this.sellerId,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ImportLog.fromMap(Map<String, Object?> map) {
    return ImportLog(
      id: map['id'] as int?,
      importType: map['import_type'] as String,
      targetTable: map['target_table'] as String?,
      fileName: map['file_name'] as String,
      filePath: map['file_path'] as String,
      importer: map['importer'] as String,
      status: (map['status'] as String?) ?? 'completed',
      processedRows: (map['processed_rows'] as num?)?.toInt() ?? 0,
      totalRows: (map['total_rows'] as num?)?.toInt() ?? 0,
      successfulRows: (map['successful_rows'] as num?)?.toInt() ?? 0,
      failedRows: (map['failed_rows'] as num?)?.toInt() ?? 0,
      errorMessage: map['error_message'] as String?,
      sellerId: map['seller_id'] as int?,
      completedAt: map['completed_at'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
