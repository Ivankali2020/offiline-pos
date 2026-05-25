class ExportLog {
  final int? id;
  final String? completedAt;
  final String fileDisk;
  final String? fileName;
  final String exporter;
  final int processedRows;
  final int totalRows;
  final int successfulRows;
  final String? createdAt;
  final String? updatedAt;

  ExportLog({
    this.id,
    this.completedAt,
    required this.fileDisk,
    this.fileName,
    required this.exporter,
    required this.processedRows,
    required this.totalRows,
    required this.successfulRows,
    this.createdAt,
    this.updatedAt,
  });

  factory ExportLog.fromMap(Map<String, Object?> map) {
    return ExportLog(
      id: map['id'] as int?,
      completedAt: map['completed_at'] as String?,
      fileDisk: map['file_disk'] as String,
      fileName: map['file_name'] as String?,
      exporter: map['exporter'] as String,
      processedRows: (map['processed_rows'] as num?)?.toInt() ?? 0,
      totalRows: (map['total_rows'] as num?)?.toInt() ?? 0,
      successfulRows: (map['successful_rows'] as num?)?.toInt() ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
