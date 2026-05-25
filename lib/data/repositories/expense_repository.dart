import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/expense.dart';

class ExpenseRepository {
  Future<List<Expense>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.rawQuery('''
      SELECT
        expanses.*,
        expanse_categories.name AS category_name,
        expanse_categories.icon AS category_icon
      FROM expanses
      INNER JOIN expanse_categories
        ON expanse_categories.id = expanses.expanse_category_id
      ORDER BY COALESCE(expanses.created_at, '') DESC, expanses.id DESC
    ''');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> insert(Expense expense) async {
    final db = await DBProvider.instance.database;
    return db.insert('expanses', expense.toMap());
  }

  Future<int> update(Expense expense) async {
    final db = await DBProvider.instance.database;
    return db.update(
      'expanses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return db.delete('expanses', where: 'id = ?', whereArgs: [id]);
  }
}
