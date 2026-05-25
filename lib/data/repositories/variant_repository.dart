import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/variant.dart';

class VariantRepository {
  Future<List<Variant>> findByProductId(int productId) async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'variants',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Variant.fromMap(map)).toList();
  }

  Future<int> insert(Variant variant) async {
    final db = await DBProvider.instance.database;
    return await db.insert('variants', variant.toMap());
  }

  Future<int> update(Variant variant) async {
    final db = await DBProvider.instance.database;
    return await db.update(
      'variants',
      variant.toMap(),
      where: 'id = ?',
      whereArgs: [variant.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return await db.delete('variants', where: 'id = ?', whereArgs: [id]);
  }
}
