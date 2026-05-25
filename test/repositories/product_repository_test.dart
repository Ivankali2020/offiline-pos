import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/data/repositories/product_repository.dart';
import 'package:abpos/models/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late ProductRepository repository;

  setUp(() async {
    // create in-memory database
    final factory = databaseFactoryFfi;
    final db = await factory.openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(version: 1, onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    }, onCreate: (db, version) async {
      // run schema from pos_schema by directly executing SQL
      // replicating only necessary tables for product tests
      await db.execute('''
CREATE TABLE sellers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL
);
''');
      await db.execute('''
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);
''');
      await db.execute('''
CREATE TABLE brands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  seller_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  FOREIGN KEY (seller_id) REFERENCES sellers(id)
);
''');
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
  updated_at TEXT,
  FOREIGN KEY (seller_id) REFERENCES sellers(id),
  FOREIGN KEY (category_id) REFERENCES categories(id),
  FOREIGN KEY (brand_id) REFERENCES brands(id)
);
''');
    }));

    // seed a seller
    await db.insert('sellers', {'name': 'Test Seller'});

    // inject into DBProvider
    await DBProvider.instance.setTestDatabase(db);

    repository = ProductRepository();
  });

  tearDown(() async {
    await DBProvider.instance.close();
  });

  test('insert and find product', () async {
    final product = Product(
      sellerId: 1,
      categoryId: null,
      brandId: null,
      supplierId: null,
      sku: 'T-1',
      name: 'Repo Product',
      description: 'desc',
      stockQuantity: 5,
      stockThreshold: 0,
      sellPrice: 10.0,
      buyPrice: 5.0,
      hasVariant: false,
      isActive: true,
    );

    final id = await repository.insert(product);
    expect(id, greaterThan(0));

    final list = await repository.findAll();
    expect(list.any((p) => p.name == 'Repo Product'), isTrue);
  });

  test('update and delete product', () async {
    final product = Product(
      sellerId: 1,
      categoryId: null,
      brandId: null,
      supplierId: null,
      sku: 'T-2',
      name: 'To Update',
      description: 'desc',
      stockQuantity: 3,
      stockThreshold: 0,
      sellPrice: 8.0,
      buyPrice: 4.0,
      hasVariant: false,
      isActive: true,
    );

    final id = await repository.insert(product);
    final listBefore = await repository.findAll();
    final inserted = listBefore.firstWhere((p) => p.id == id);

    final updated = Product(
      id: inserted.id,
      sellerId: inserted.sellerId,
      categoryId: inserted.categoryId,
      brandId: inserted.brandId,
      supplierId: inserted.supplierId,
      sku: inserted.sku,
      name: 'Updated Name',
      description: inserted.description,
      stockQuantity: inserted.stockQuantity + 1,
      stockThreshold: inserted.stockThreshold,
      sellPrice: inserted.sellPrice + 2,
      buyPrice: inserted.buyPrice,
      hasVariant: inserted.hasVariant,
      isActive: inserted.isActive,
    );

    await repository.update(updated);
    final listAfterUpdate = await repository.findAll();
    expect(listAfterUpdate.any((p) => p.name == 'Updated Name'), isTrue);

    await repository.delete(updated.id!);
    final listAfterDelete = await repository.findAll();
    expect(listAfterDelete.any((p) => p.id == updated.id), isFalse);
  });
}
