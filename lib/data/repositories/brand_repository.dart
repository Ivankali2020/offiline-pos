import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/brand.dart';

class BrandRepository {
  Future<List<Brand>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('brands', orderBy: 'name ASC');
    return maps.map((map) => Brand.fromMap(map)).toList();
  }

  Future<int> insert(Brand brand) async {
    final db = await DBProvider.instance.database;
    return await db.insert('brands', brand.toMap());
  }

  Future<int> update(Brand brand) async {
    final db = await DBProvider.instance.database;
    return await db.update('brands', brand.toMap(), where: 'id = ?', whereArgs: [brand.id]);
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return await db.delete('brands', where: 'id = ?', whereArgs: [id]);
  }
}
