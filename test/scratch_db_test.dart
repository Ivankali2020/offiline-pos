import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/data/local/pos_schema.dart';
import 'package:abpos/data/repositories/dashboard_repository.dart';
import 'package:abpos/data/repositories/order_repository.dart';
import 'package:abpos/data/repositories/purchase_repository.dart';
import 'package:abpos/models/order.dart';
import 'package:abpos/models/purchase.dart';
import 'package:abpos/models/purchase_product.dart';

void main() {
  sqfliteFfiInit();

  test('Fresh schema accepts bundled seed data', () async {
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 8,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          for (final script in [
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
          ]) {
            await db.execute(script);
          }
        },
      ),
    );

    await DBProvider.instance.seedDevData(db);

    final supplierCount =
        (await db.rawQuery(
              'SELECT COUNT(*) AS count FROM suppliers',
            )).first['count']
            as int;
    final purchaseLineCount =
        (await db.rawQuery(
              'SELECT COUNT(*) AS count FROM purchase_products',
            )).first['count']
            as int;

    expect(supplierCount, greaterThan(0));
    expect(purchaseLineCount, greaterThan(0));

    await db.close();
  });

  test('Database backup export copies file and logs export history', () async {
    final factory = databaseFactoryFfi;
    final tempDir = await Directory.systemTemp.createTemp('abpos-export-test');
    final dbPath = p.join(tempDir.path, 'abpos.db');
    final db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 8,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          for (final script in [
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
          ]) {
            await db.execute(script);
          }
        },
      ),
    );

    await DBProvider.instance.setTestDatabase(db);
    final exportPath = await DBProvider.instance.exportDatabaseBackup(
      targetDirectoryOverride: tempDir.path,
      exporter: 'test',
    );

    expect(await File(exportPath).exists(), isTrue);

    final reopenedDb = await DBProvider.instance.database;
    final count =
        (await reopenedDb.rawQuery(
              'SELECT COUNT(*) AS count FROM exports',
            )).first['count']
            as int;
    expect(count, equals(1));

    await DBProvider.instance.close();
    await tempDir.delete(recursive: true);
  });

  test('Database backup import replaces live data and logs import history', () async {
    final factory = databaseFactoryFfi;
    final tempDir = await Directory.systemTemp.createTemp('abpos-import-test');
    final livePath = p.join(tempDir.path, 'live.db');
    final backupPath = p.join(tempDir.path, 'backup.db');

    Future<Database> createFullDb(String path, String storeName) async {
      return factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 8,
          singleInstance: false,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            for (final script in [
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
            ]) {
              await db.execute(script);
            }
            await db.insert('sellers', {
              'id': 1,
              'name': storeName,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          },
        ),
      );
    }

    final liveDb = await createFullDb(livePath, 'Live Store');
    final backupDb = await createFullDb(backupPath, 'Backup Store');
    await backupDb.close();

    await DBProvider.instance.setTestDatabase(liveDb);
    await DBProvider.instance.importDatabaseBackup(backupPath, importer: 'test');

    final reopenedDb = await DBProvider.instance.database;
    final sellers = await reopenedDb.query('sellers', orderBy: 'id ASC');
    final imports =
        (await reopenedDb.rawQuery(
              'SELECT COUNT(*) AS count FROM imports',
            )).first['count']
            as int;

    expect(sellers.first['name'], equals('Backup Store'));
    expect(imports, equals(1));

    await DBProvider.instance.close();
    await tempDir.delete(recursive: true);
  });

  test('Check SQLite date logic', () async {
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 6,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          // Let's create orders table
          await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_number TEXT NOT NULL UNIQUE,
            seller_id INTEGER NOT NULL,
            customer_name TEXT,
            customer_phone TEXT,
            status TEXT NOT NULL DEFAULT 'new',
            sub_total REAL NOT NULL DEFAULT 0,
            delivery_fees REAL NOT NULL DEFAULT 0,
            total_price REAL NOT NULL DEFAULT 0,
            payment_id INTEGER,
            payment_account_id INTEGER,
            tax REAL NOT NULL DEFAULT 0,
            tax_price REAL NOT NULL DEFAULT 0,
            given_amount REAL NOT NULL DEFAULT 0,
            change_amount REAL NOT NULL DEFAULT 0,
            note TEXT,
            image_path TEXT,
            created_at TEXT,
            updated_at TEXT
          );
        ''');
        },
      ),
    );

    await DBProvider.instance.setTestDatabase(db);

    final now = DateTime.now();
    final isoString = now.toIso8601String();

    final orderRepo = OrderRepository();
    final dashboardRepo = DashboardRepository();

    await orderRepo.insert(
      Order(
        invoiceNumber: 'INV-1',
        sellerId: 1,
        status: 'completed',
        subTotal: 100,
        deliveryFees: 0,
        totalPrice: 100,
        tax: 0,
        taxPrice: 0,
        givenAmount: 100,
        changeAmount: 0,
        createdAt: isoString,
        updatedAt: isoString,
      ),
    );

    // Run trend for this month
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final trendPoints = await dashboardRepo.orderTrend(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    expect(trendPoints.length, equals(1));
  });

  test('Dashboard expense totals include saved expenses', () async {
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 7,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE expanse_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              icon TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE expanses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              expanse_category_id INTEGER NOT NULL,
              amount REAL NOT NULL DEFAULT 0,
              description TEXT,
              payment_method TEXT NOT NULL,
              created_at TEXT,
              updated_at TEXT,
              FOREIGN KEY (expanse_category_id) REFERENCES expanse_categories(id)
            );
          ''');
          await db.execute('''
            CREATE TABLE order_products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              order_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              variant_id INTEGER,
              attributes TEXT,
              price REAL NOT NULL DEFAULT 0,
              discount_price REAL NOT NULL DEFAULT 0,
              discount REAL NOT NULL DEFAULT 0,
              quantity INTEGER NOT NULL DEFAULT 1,
              profit REAL NOT NULL DEFAULT 0,
              original_buy_price REAL NOT NULL DEFAULT 0,
              original_price REAL NOT NULL DEFAULT 0,
              total_refunded_amount REAL NOT NULL DEFAULT 0,
              created_at TEXT,
              updated_at TEXT
            );
          ''');
        },
      ),
    );

    await DBProvider.instance.setTestDatabase(db);

    await db.insert('expanse_categories', {
      'name': 'Rent',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('expanses', {
      'expanse_category_id': 1,
      'amount': 25000,
      'description': 'Shop rent',
      'payment_method': 'Cash',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    await db.insert('order_products', {
      'order_id': 1,
      'product_id': 1,
      'quantity': 2,
      'profit': 20000,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final dashboardRepo = DashboardRepository();

    final totalExpenses = await dashboardRepo.totalExpenses();
    final totalProfit = await dashboardRepo.totalProfit();

    expect(totalExpenses, equals(25000));
    expect(totalProfit, equals(40000));
  });

  test('Completing a purchase imports stock quantities', () async {
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 8,
        singleInstance: false,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              seller_id INTEGER NOT NULL,
              category_id INTEGER,
              brand_id INTEGER,
              supplier_id INTEGER,
              sku TEXT,
              name TEXT NOT NULL,
              description TEXT,
              stock_quantity INTEGER NOT NULL DEFAULT 0,
              stock_threshold INTEGER NOT NULL DEFAULT 0,
              sell_price REAL NOT NULL DEFAULT 0,
              buy_price REAL NOT NULL DEFAULT 0,
              has_variant INTEGER NOT NULL DEFAULT 0,
              is_active INTEGER NOT NULL DEFAULT 1,
              created_at TEXT,
              updated_at TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE purchases (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_number TEXT NOT NULL UNIQUE,
              seller_id INTEGER NOT NULL,
              supplier_id INTEGER,
              total_amount REAL NOT NULL DEFAULT 0,
              paid_amount REAL NOT NULL DEFAULT 0,
              due_amount REAL NOT NULL DEFAULT 0,
              status TEXT NOT NULL DEFAULT 'pending',
              note TEXT,
              created_at TEXT,
              updated_at TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE purchase_products (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              purchase_id INTEGER NOT NULL,
              product_id INTEGER NOT NULL,
              variant_id INTEGER,
              quantity INTEGER NOT NULL DEFAULT 0,
              cost_price REAL NOT NULL DEFAULT 0,
              sell_price REAL NOT NULL DEFAULT 0,
              total_cost REAL NOT NULL DEFAULT 0,
              created_at TEXT,
              updated_at TEXT
            );
          ''');
          await db.execute('''
            CREATE TABLE variants (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              product_id INTEGER NOT NULL,
              name TEXT,
              attributes TEXT,
              sku TEXT,
              stock_quantity INTEGER NOT NULL DEFAULT 0,
              sell_price REAL NOT NULL DEFAULT 0,
              buy_price REAL NOT NULL DEFAULT 0,
              created_at TEXT,
              updated_at TEXT
            );
          ''');
        },
      ),
    );

    await DBProvider.instance.setTestDatabase(db);

    await db.insert('products', {
      'seller_id': 1,
      'name': 'Test Product',
      'stock_quantity': 5,
      'stock_threshold': 0,
      'sell_price': 2000,
      'buy_price': 1000,
      'has_variant': 0,
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    final repository = PurchaseRepository();
    final purchaseId = await repository.savePurchaseWithProducts(
      Purchase(
        invoiceNumber: 'PUR-1',
        sellerId: 1,
        totalAmount: 3000,
        paidAmount: 1000,
        dueAmount: 2000,
        status: 'pending',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
      [
        PurchaseProduct(
          purchaseId: 0,
          productId: 1,
          quantity: 3,
          costPrice: 1000,
          totalCost: 3000,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      ],
    );

    await repository.completePurchase(purchaseId);

    final product = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    final purchase = await db.query(
      'purchases',
      where: 'id = ?',
      whereArgs: [purchaseId],
      limit: 1,
    );

    expect(product.first['stock_quantity'], equals(8));
    expect(purchase.first['status'], equals('completed'));
  });
}
