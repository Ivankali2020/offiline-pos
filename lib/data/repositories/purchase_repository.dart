import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/purchase.dart';
import 'package:abpos/models/purchase_product.dart';

class PurchaseRepository {
  Future<List<Purchase>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('purchases', orderBy: 'created_at DESC');
    return maps.map((map) => Purchase.fromMap(map)).toList();
  }

  Future<List<PurchaseProduct>> findProductsByPurchaseId(int purchaseId) async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery(
      '''
      SELECT
        pp.*,
        p.name AS product_name,
        v.name AS variant_name
      FROM purchase_products pp
      LEFT JOIN products p ON p.id = pp.product_id
      LEFT JOIN variants v ON v.id = pp.variant_id
      WHERE pp.purchase_id = ?
      ORDER BY pp.id ASC
      ''',
      [purchaseId],
    );

    return maps.map((map) => PurchaseProduct.fromMap(map)).toList();
  }

  Future<int> savePurchaseWithProducts(
    Purchase purchase,
    List<PurchaseProduct> products,
  ) async {
    final db = await DBProvider.instance.database;
    return db.transaction((txn) async {
      final purchaseId = await txn.insert('purchases', purchase.toMap());
      for (final item in products) {
        final itemMap = item.toMap();
        itemMap['purchase_id'] = purchaseId;
        await txn.insert('purchase_products', itemMap);
      }
      return purchaseId;
    });
  }

  Future<Purchase?> findById(int id) async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('purchases', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Purchase.fromMap(maps.first);
  }

  Future<void> completePurchase(int purchaseId) async {
    final db = await DBProvider.instance.database;
    await db.transaction((txn) async {
      final purchases = await txn.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [purchaseId],
        limit: 1,
      );
      if (purchases.isEmpty) {
        throw StateError('Purchase not found');
      }

      final current = Purchase.fromMap(purchases.first);
      if (current.status.trim().toLowerCase() == 'completed') {
        return;
      }

      final items = await txn.query(
        'purchase_products',
        where: 'purchase_id = ?',
        whereArgs: [purchaseId],
      );

      for (final row in items) {
        final productId = row['product_id'] as int;
        final variantId = row['variant_id'] as int?;
        final quantity = row['quantity'] as int;

        await txn.rawUpdate(
          '''
          UPDATE products
          SET
            stock_quantity = stock_quantity + ?,
            updated_at = ?
          WHERE id = ?
          ''',
          [quantity, DateTime.now().toIso8601String(), productId],
        );

        if (variantId != null) {
          await txn.rawUpdate(
            '''
            UPDATE variants
            SET
              stock_quantity = stock_quantity + ?,
              updated_at = ?
            WHERE id = ?
            ''',
            [quantity, DateTime.now().toIso8601String(), variantId],
          );
        }
      }

      await txn.update(
        'purchases',
        {'status': 'completed', 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [purchaseId],
      );
    });
  }
}
