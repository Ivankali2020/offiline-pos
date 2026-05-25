import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/category.dart';

class CategoryRepository {
  Future<List<Category>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insert(Category category) async {
    final db = await DBProvider.instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> update(Category category) async {
    final db = await DBProvider.instance.database;
    return await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
