import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/expense_category.dart';

class ExpenseCategoryRepository {
  Future<List<ExpenseCategory>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('expanse_categories', orderBy: 'name ASC');
    return maps.map((map) => ExpenseCategory.fromMap(map)).toList();
  }

  Future<int> insert(ExpenseCategory category) async {
    final db = await DBProvider.instance.database;
    return db.insert('expanse_categories', category.toMap());
  }

  Future<int> update(ExpenseCategory category) async {
    final db = await DBProvider.instance.database;
    return db.update(
      'expanse_categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return db.delete('expanse_categories', where: 'id = ?', whereArgs: [id]);
  }
}
