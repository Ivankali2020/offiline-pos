import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_seed.dart';
import 'db_seed_orders.dart';
import 'pos_schema.dart';
import 'db_products.dart';

class DBProvider {
  DBProvider._();

  static final DBProvider instance = DBProvider._();

  Database? _database;
  Completer<Database>? _initCompleter;
  bool _includeDevDataOnCreate = true;

  static const List<String> _requiredBackupTables = [
    'sellers',
    'regions',
    'townships',
    'categories',
    'brands',
    'suppliers',
    'payments',
    'payment_accounts',
    'products',
    'variants',
    'orders',
    'order_products',
    'order_returns',
    'order_return_products',
    'purchases',
    'purchase_products',
    'expanse_categories',
    'expanses',
    'printers',
    'settings',
    'attributes',
    'attribute_values',
    'product_attribute_values',
  ];

  Future<Database> get database async {
    if (_database != null) return _database!;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<Database>();
    try {
      final db = await initDB();
      _initCompleter!.complete(db);
      return db;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  Future<void> setTestDatabase(Database db) async {
    await close();
    _database = db;
  }

  Future<Database> initDB({bool includeDevData = true}) async {
    final path = await databasePath();
    return _openDatabaseAtPath(path, includeDevData: includeDevData);
  }

  Future<Database> resetAndSeedDatabase() async {
    final path = await currentDatabasePath();
    await close();
    _initCompleter = null;
    await deleteDatabase(path);
    return _openDatabaseAtPath(path, includeDevData: true);
  }

  Future<Database> resetDatabaseToDefaults() async {
    final path = await currentDatabasePath();
    await close();
    _initCompleter = null;
    await deleteDatabase(path);
    return _openDatabaseAtPath(path, includeDevData: false);
  }

  Future<String> databasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, 'abpos.db');
  }

  Future<String> currentDatabasePath() async {
    final db = _database;
    if (db != null && db.isOpen) {
      final rows = await db.rawQuery('PRAGMA database_list');
      for (final row in rows) {
        final file = row['file'] as String?;
        if (file != null && file.trim().isNotEmpty) {
          return file;
        }
      }
    }
    return databasePath();
  }

  Future<String> exportDatabaseBackup({
    String exporter = 'backup_page',
    String? targetDirectoryOverride,
  }) async {
    final sourcePath = await currentDatabasePath();
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Database file not found.');
    }

    await close();

    final baseDirectory = targetDirectoryOverride == null
        ? Directory(
            join((await getApplicationDocumentsDirectory()).path, 'backups'),
          )
        : Directory(targetDirectoryOverride);
    await baseDirectory.create(recursive: true);

    final timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final backupPath = join(baseDirectory.path, 'abpos-backup-$timestamp.db');
    await sourceFile.copy(backupPath);

    await _openDatabaseAtPath(sourcePath, includeDevData: true);
    await _logExport(filePath: backupPath, exporter: exporter);
    return backupPath;
  }

  Future<void> importDatabaseBackup(
    String sourcePath, {
    String importer = 'backup_page',
    int sellerId = 1,
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw Exception('Selected backup file could not be found.');
    }

    await _validateBackupFile(sourcePath);

    final destinationPath = await currentDatabasePath();
    await close();
    _initCompleter = null;

    if (sourcePath != destinationPath) {
      await file.copy(destinationPath);
    }

    final db = await _openDatabaseAtPath(destinationPath, includeDevData: true);
    await _ensureLogTables(db);
    await _logImport(
      filePath: sourcePath,
      fileName: basename(sourcePath),
      importer: importer,
      sellerId: sellerId,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    final createScripts = [
      createSellerTable,
      createRegionTable,
      createTownshipTable,
      createCategoryTable,
      createBrandTable,
      createSupplierTable,
      createPaymentTable,
      createPaymentAccountTable,
      createProductTable,
      createVariantTable,
      createOrderTable,
      createOrderProductTable,
      createOrderReturnTable,
      createOrderReturnProductsTable,
      createPurchaseTable,
      createPurchaseProductTable,
      createExpenseCategoryTable,
      createExpenseTable,
      createPrinterTable,
      createSettingsTable,
      createExportTable,
      createImportTable,
      createAttributeTable,
      createAttributeValueTable,
      createProductAttributeValueTable,
    ];

    for (final script in createScripts) {
      await db.execute(script);
    }

    await _seedDefaults(db);
    if (_includeDevDataOnCreate) {
      await seedDevData(db);
    }
  }

  Future<void> seedDevData(Database db) async {
    final tables = {
      'sellers': DBSeed.sellers,
      'categories': DBSeed.categories,
      'brands': DBSeed.brands,
      'suppliers': DBSeed.suppliers,
      'attributes': DBSeed.attributes,
      'attribute_values': DBSeed.attributeValues,
      'products': DbProducts.products,
      'product_attribute_values': DBSeed.productAttributeValues,
      'expanse_categories': DBSeed.expenseCategoriesSeed,
      'expanses': DBSeed.expensesSeed,
      'purchases': DBSeed.purchasesSeed,
      'purchase_products': DBSeed.purchaseProductsSeed,
      'orders': DBSeedOrders.orders,
      'order_products': DBSeedOrders.orderProducts,
    };

    for (var entry in tables.entries) {
      for (var row in entry.value) {
        await db.insert(
          entry.key,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<void> _seedDefaults(Database db) async {
    await db.insert('sellers', {
      'name': 'My Store',
      'phone': '',
      'email': '',
      'address': '',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('payments', {
      'name': 'Cash',
      'note': 'Local cash payment',
      'is_published': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    await db.insert('settings', {
      'seller_id': 1,
      'store_name': 'My Store',
      'receipt_phone': '',
      'receipt_address': '',
      'currency_code': 'MMK',
      'currency_symbol': 'Ks',
      'receipt_header': 'AB POS Receipt',
      'receipt_footer': 'Thank you for shopping',
      'tax_rate': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> _openDatabaseAtPath(
    String path, {
    required bool includeDevData,
  }) async {
    _includeDevDataOnCreate = includeDevData;
    _database = await openDatabase(
      path,
      version: 8,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
    await _ensureLogTables(_database!);
    await _ensureExpenseTransactionType(_database!);
    return _database!;
  }

  Future<void> _ensureLogTables(Database db) async {
    await db.execute(createExportTable);
    await db.execute(createImportTable);
  }

  Future<void> _ensureExpenseTransactionType(Database db) async {
    try {
      await db.execute(
        "ALTER TABLE expanses ADD COLUMN transaction_type TEXT NOT NULL DEFAULT 'expense'",
      );
    } catch (_) {
      // Column already exists — safe to ignore
    }
  }

  Future<void> _validateBackupFile(String sourcePath) async {
    Database? validationDb;
    try {
      validationDb = await openDatabase(sourcePath, readOnly: true);
      final rows = await validationDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tableNames = rows
          .map((row) => row['name'] as String?)
          .whereType<String>()
          .toSet();
      final missingTables = _requiredBackupTables
          .where((table) => !tableNames.contains(table))
          .toList();
      if (missingTables.isNotEmpty) {
        throw Exception(
          'Selected file is not a valid AB POS backup. Missing tables: ${missingTables.join(', ')}',
        );
      }
    } on DatabaseException catch (error) {
      throw Exception('Selected file is not a readable SQLite backup. $error');
    } finally {
      await validationDb?.close();
    }
  }

  Future<void> _logExport({
    required String filePath,
    required String exporter,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('exports', {
      'completed_at': now,
      'file_disk': filePath,
      'file_name': basename(filePath),
      'exporter': exporter,
      'processed_rows': 1,
      'total_rows': 1,
      'successful_rows': 1,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _logImport({
    required String filePath,
    required String fileName,
    required String importer,
    required int sellerId,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert('imports', {
      'import_type': 'db_restore',
      'target_table': null,
      'file_name': fileName,
      'file_path': filePath,
      'importer': importer,
      'status': 'completed',
      'processed_rows': 1,
      'total_rows': 1,
      'successful_rows': 1,
      'failed_rows': 0,
      'error_message': null,
      'seller_id': sellerId,
      'completed_at': now,
      'created_at': now,
      'updated_at': now,
    });
  }
}
