import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/product.dart';
import 'package:abpos/models/product_attribute_selection.dart';

class ProductRepository {
  static const String _productQuery = '''
    SELECT p.*, c.name as category_name, b.name as brand_name
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
    LEFT JOIN brands b ON p.brand_id = b.id
  ''';

  Future<List<Product>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery('$_productQuery ORDER BY p.id ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> insert(Product product) async {
    final db = await DBProvider.instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> update(Product product) async {
    final db = await DBProvider.instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return await db.transaction((txn) async {
      await txn.delete(
        'product_attribute_values',
        where: 'product_id = ?',
        whereArgs: [id],
      );
      await txn.delete('variants', where: 'product_id = ?', whereArgs: [id]);
      return await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Product>> search(String query) async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery(
      '$_productQuery WHERE LOWER(p.name) LIKE ? OR LOWER(p.sku) LIKE ? ORDER BY p.name ASC',
      ['%${query.toLowerCase()}%', '%${query.toLowerCase()}%'],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<ProductAttributeSelection>> findAttributeSelections(
    int productId,
  ) async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery(
      '''
      SELECT
        pav.*,
        a.name AS attribute_name,
        a.type AS attribute_type,
        av.value AS value,
        av.color_code AS color_code
      FROM product_attribute_values pav
      INNER JOIN attributes a ON pav.attribute_id = a.id
      INNER JOIN attribute_values av ON pav.attribute_value_id = av.id
      WHERE pav.product_id = ?
      ORDER BY a.name ASC, av.value ASC
      ''',
      [productId],
    );
    return maps.map(ProductAttributeSelection.fromMap).toList();
  }

  Future<void> replaceAttributeSelections(
    int productId,
    List<ProductAttributeSelection> selections,
  ) async {
    final db = await DBProvider.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.delete(
        'product_attribute_values',
        where: 'product_id = ?',
        whereArgs: [productId],
      );

      for (final selection in selections) {
        await txn.insert('product_attribute_values', {
          'product_id': productId,
          'attribute_id': selection.attributeId,
          'attribute_value_id': selection.attributeValueId,
          'created_at': now,
          'updated_at': now,
        });
      }
    });
  }
}
