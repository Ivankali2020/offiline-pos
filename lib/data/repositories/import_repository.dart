import 'dart:io';

import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/import_log.dart';
import 'package:path/path.dart';

/// Handles all CSV parsing and database insertion for each import type.
///
/// Conventions:
/// - Categories / Brands / Expense Categories: skip row if name already exists.
/// - Products: upsert — update if name OR sku matches, insert otherwise.
/// - Expenses: always insert; resolve category_name → id (create if missing).
class CsvImportRepository {
  static const String _importer = 'import_page';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<ImportLog> importCategories(String csvPath, int sellerId) async {
    final rows = await _readCsv(csvPath);
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = _cell(row, 'name');
        if (name.isEmpty) {
          failed++;
          errors.add('Row ${i + 1}: missing name');
          continue;
        }

        // Check duplicate
        final existing = await txn.query(
          'categories',
          where: 'LOWER(name) = ? AND seller_id = ?',
          whereArgs: [name.toLowerCase(), sellerId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          failed++;
          errors.add('Row ${i + 1}: "$name" already exists — skipped');
          continue;
        }

        final isSubRaw = _cell(row, 'is_sub_category');
        final isSub = isSubRaw == '1' || isSubRaw.toLowerCase() == 'true';

        await txn.insert('categories', {
          'seller_id': sellerId,
          'parent_id': null,
          'name': name,
          'description': _cell(row, 'description').nullIfEmpty,
          'is_sub_category': isSub ? 1 : 0,
          'created_at': now,
          'updated_at': now,
        });
        successful++;
      }
    });

    return _log(
      filePath: csvPath,
      importType: 'categories',
      targetTable: 'categories',
      totalRows: rows.length,
      successfulRows: successful,
      failedRows: failed,
      errorMessage: errors.isEmpty ? null : errors.take(10).join('\n'),
      sellerId: sellerId,
    );
  }

  Future<ImportLog> importBrands(String csvPath, int sellerId) async {
    final rows = await _readCsv(csvPath);
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = _cell(row, 'name');
        if (name.isEmpty) {
          failed++;
          errors.add('Row ${i + 1}: missing name');
          continue;
        }

        final existing = await txn.query(
          'brands',
          where: 'LOWER(name) = ? AND seller_id = ?',
          whereArgs: [name.toLowerCase(), sellerId],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          failed++;
          errors.add('Row ${i + 1}: "$name" already exists — skipped');
          continue;
        }

        await txn.insert('brands', {
          'seller_id': sellerId,
          'name': name,
          'description': _cell(row, 'description').nullIfEmpty,
          'created_at': now,
          'updated_at': now,
        });
        successful++;
      }
    });

    return _log(
      filePath: csvPath,
      importType: 'brands',
      targetTable: 'brands',
      totalRows: rows.length,
      successfulRows: successful,
      failedRows: failed,
      errorMessage: errors.isEmpty ? null : errors.take(10).join('\n'),
      sellerId: sellerId,
    );
  }

  Future<ImportLog> importExpenseCategories(String csvPath) async {
    final rows = await _readCsv(csvPath);
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = _cell(row, 'name');
        if (name.isEmpty) {
          failed++;
          errors.add('Row ${i + 1}: missing name');
          continue;
        }

        final existing = await txn.query(
          'expanse_categories',
          where: 'LOWER(name) = ?',
          whereArgs: [name.toLowerCase()],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          failed++;
          errors.add('Row ${i + 1}: "$name" already exists — skipped');
          continue;
        }

        await txn.insert('expanse_categories', {
          'name': name,
          'icon': _cell(row, 'icon').nullIfEmpty,
          'created_at': now,
          'updated_at': now,
        });
        successful++;
      }
    });

    return _log(
      filePath: csvPath,
      importType: 'expense_categories',
      targetTable: 'expanse_categories',
      totalRows: rows.length,
      successfulRows: successful,
      failedRows: failed,
      errorMessage: errors.isEmpty ? null : errors.take(10).join('\n'),
    );
  }

  Future<ImportLog> importExpenses(String csvPath) async {
    final rows = await _readCsv(csvPath);
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();
    int successful = 0;
    int failed = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final categoryName = _cell(row, 'category_name');
        final amountStr = _cell(row, 'amount');
        final amount = double.tryParse(amountStr);

        if (categoryName.isEmpty) {
          failed++;
          errors.add('Row ${i + 1}: missing category_name');
          continue;
        }
        if (amount == null) {
          failed++;
          errors.add('Row ${i + 1}: invalid amount "$amountStr"');
          continue;
        }

        // Resolve or create expense category
        final catId = await _resolveOrCreateExpenseCategory(
          txn,
          categoryName,
          now,
        );

        final dateRaw = _cell(row, 'date');
        final createdAt = dateRaw.isEmpty ? now : '${dateRaw}T00:00:00.000';

        await txn.insert('expanses', {
          'expanse_category_id': catId,
          'amount': amount,
          'description': _cell(row, 'description').nullIfEmpty,
          'payment_method': _cell(row, 'payment_method').let(
            (v) => v.isEmpty ? 'Cash' : v,
          ),
          'created_at': createdAt,
          'updated_at': now,
        });
        successful++;
      }
    });

    return _log(
      filePath: csvPath,
      importType: 'expenses',
      targetTable: 'expanses',
      totalRows: rows.length,
      successfulRows: successful,
      failedRows: failed,
      errorMessage: errors.isEmpty ? null : errors.take(10).join('\n'),
    );
  }

  Future<ImportLog> importProducts(String csvPath, int sellerId) async {
    final rows = await _readCsv(csvPath);
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();
    int inserted = 0;
    int updated = 0;
    int failed = 0;
    final errors = <String>[];

    await db.transaction((txn) async {
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        final name = _cell(row, 'name');
        final sku = _cell(row, 'sku').nullIfEmpty;

        if (name.isEmpty) {
          failed++;
          errors.add('Row ${i + 1}: missing name');
          continue;
        }

        final sellPriceStr = _cell(row, 'sell_price');
        final buyPriceStr = _cell(row, 'buy_price');
        final stockStr = _cell(row, 'stock_quantity');
        final thresholdStr = _cell(row, 'stock_threshold');

        final sellPrice = double.tryParse(sellPriceStr) ?? 0.0;
        final buyPrice = double.tryParse(buyPriceStr) ?? 0.0;
        final stockQuantity = int.tryParse(stockStr) ?? 0;
        final stockThreshold = int.tryParse(thresholdStr) ?? 0;

        final isActiveRaw = _cell(row, 'is_active');
        final isActive = isActiveRaw.isEmpty ||
            isActiveRaw == '1' ||
            isActiveRaw.toLowerCase() == 'true';

        // Resolve FK: category
        final categoryName = _cell(row, 'category_name').nullIfEmpty;
        int? categoryId;
        if (categoryName != null) {
          categoryId = await _resolveOrCreateCategory(
            txn,
            categoryName,
            sellerId,
            now,
          );
        }

        // Resolve FK: brand
        final brandName = _cell(row, 'brand_name').nullIfEmpty;
        int? brandId;
        if (brandName != null) {
          brandId = await _resolveOrCreateBrand(txn, brandName, sellerId, now);
        }

        final data = {
          'seller_id': sellerId,
          'category_id': categoryId,
          'brand_id': brandId,
          'sku': sku,
          'name': name,
          'description': _cell(row, 'description').nullIfEmpty,
          'sell_price': sellPrice,
          'buy_price': buyPrice,
          'stock_quantity': stockQuantity,
          'stock_threshold': stockThreshold,
          'has_variant': 0,
          'is_active': isActive ? 1 : 0,
          'updated_at': now,
        };

        // Look for existing product by name or SKU
        List<Map<String, Object?>> existing = [];
        if (sku != null && sku.isNotEmpty) {
          existing = await txn.query(
            'products',
            where: '(LOWER(name) = ? OR LOWER(sku) = ?) AND seller_id = ?',
            whereArgs: [name.toLowerCase(), sku.toLowerCase(), sellerId],
            limit: 1,
          );
        } else {
          existing = await txn.query(
            'products',
            where: 'LOWER(name) = ? AND seller_id = ?',
            whereArgs: [name.toLowerCase(), sellerId],
            limit: 1,
          );
        }

        if (existing.isNotEmpty) {
          final existingId = existing.first['id'] as int;
          await txn.update(
            'products',
            data,
            where: 'id = ?',
            whereArgs: [existingId],
          );
          updated++;
        } else {
          await txn.insert('products', {
            ...data,
            'supplier_id': null,
            'created_at': now,
          });
          inserted++;
        }
      }
    });

    final successful = inserted + updated;
    return _log(
      filePath: csvPath,
      importType: 'products',
      targetTable: 'products',
      totalRows: rows.length,
      successfulRows: successful,
      failedRows: failed,
      errorMessage: errors.isEmpty ? null : errors.take(10).join('\n'),
      sellerId: sellerId,
      extraNote: updated > 0 ? '$updated updated, $inserted inserted' : null,
    );
  }

  Future<List<ImportLog>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'imports',
      where: "import_type != 'db_restore'",
      orderBy: 'COALESCE(completed_at, created_at) DESC, id DESC',
      limit: 50,
    );
    return maps.map((map) => ImportLog.fromMap(map)).toList();
  }

  // ---------------------------------------------------------------------------
  // FK helpers
  // ---------------------------------------------------------------------------

  Future<int> _resolveOrCreateCategory(
    dynamic txn,
    String name,
    int sellerId,
    String now,
  ) async {
    final existing = await txn.query(
      'categories',
      where: 'LOWER(name) = ? AND seller_id = ?',
      whereArgs: [name.toLowerCase(), sellerId],
      limit: 1,
    ) as List<Map<String, Object?>>;
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await txn.insert('categories', {
      'seller_id': sellerId,
      'name': name,
      'parent_id': null,
      'description': null,
      'is_sub_category': 0,
      'created_at': now,
      'updated_at': now,
    }) as int;
  }

  Future<int> _resolveOrCreateBrand(
    dynamic txn,
    String name,
    int sellerId,
    String now,
  ) async {
    final existing = await txn.query(
      'brands',
      where: 'LOWER(name) = ? AND seller_id = ?',
      whereArgs: [name.toLowerCase(), sellerId],
      limit: 1,
    ) as List<Map<String, Object?>>;
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await txn.insert('brands', {
      'seller_id': sellerId,
      'name': name,
      'description': null,
      'created_at': now,
      'updated_at': now,
    }) as int;
  }

  Future<int> _resolveOrCreateExpenseCategory(
    dynamic txn,
    String name,
    String now,
  ) async {
    final existing = await txn.query(
      'expanse_categories',
      where: 'LOWER(name) = ?',
      whereArgs: [name.toLowerCase()],
      limit: 1,
    ) as List<Map<String, Object?>>;
    if (existing.isNotEmpty) return existing.first['id'] as int;
    return await txn.insert('expanse_categories', {
      'name': name,
      'icon': null,
      'created_at': now,
      'updated_at': now,
    }) as int;
  }

  // ---------------------------------------------------------------------------
  // Logging
  // ---------------------------------------------------------------------------

  Future<ImportLog> _log({
    required String filePath,
    required String importType,
    required String targetTable,
    required int totalRows,
    required int successfulRows,
    required int failedRows,
    String? errorMessage,
    int? sellerId,
    String? extraNote,
  }) async {
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();
    final fileName = basename(filePath);
    final status = failedRows == totalRows ? 'failed' : 'completed';

    final note = [
      extraNote,
      errorMessage,
    ].whereType<String>().join('\n').trim();

    await db.insert('imports', {
      'import_type': importType,
      'target_table': targetTable,
      'file_name': fileName,
      'file_path': filePath,
      'importer': _importer,
      'status': status,
      'processed_rows': totalRows,
      'total_rows': totalRows,
      'successful_rows': successfulRows,
      'failed_rows': failedRows,
      'error_message': note.isEmpty ? null : note,
      'seller_id': sellerId,
      'completed_at': now,
      'created_at': now,
      'updated_at': now,
    });

    return ImportLog(
      importType: importType,
      targetTable: targetTable,
      fileName: fileName,
      filePath: filePath,
      importer: _importer,
      status: status,
      processedRows: totalRows,
      totalRows: totalRows,
      successfulRows: successfulRows,
      failedRows: failedRows,
      errorMessage: note.isEmpty ? null : note,
      sellerId: sellerId,
      completedAt: now,
      createdAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // CSV parser (RFC 4180 subset — handles double-quoted fields)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, String>>> _readCsv(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('CSV file not found: $path');
    }
    final lines = await file.readAsLines();
    if (lines.isEmpty) return [];

    final headers = _parseLine(lines.first);
    final result = <Map<String, String>>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cells = _parseLine(line);
      final map = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        map[headers[j].trim()] = j < cells.length ? cells[j] : '';
      }
      result.add(map);
    }
    return result;
  }

  List<String> _parseLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  String _cell(Map<String, String> row, String key) =>
      (row[key] ?? '').trim();
}

// Utility extensions
extension _StringX on String {
  String? get nullIfEmpty => isEmpty ? null : this;
  String let(String Function(String) fn) => fn(this);
}
