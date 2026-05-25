import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/supplier.dart';

class SupplierRepository {
  Future<List<Supplier>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('suppliers', orderBy: 'name ASC');
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<int> insert(Supplier supplier) async {
    final db = await DBProvider.instance.database;
    return db.insert('suppliers', supplier.toMap());
  }

  Future<int> update(Supplier supplier) async {
    final db = await DBProvider.instance.database;
    return db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}
