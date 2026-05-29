import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/printer.dart';

class PrinterRepository {
  Future<List<Printer>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('printers', orderBy: 'is_default DESC, name ASC');
    return maps.map((map) => Printer.fromMap(map)).toList();
  }

  Future<Printer?> findDefault() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'printers',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Printer.fromMap(maps.first);
  }

  Future<int> insert(Printer printer) async {
    final db = await DBProvider.instance.database;
    if (printer.isDefault) {
      await db.update('printers', {'is_default': 0});
    }
    return db.insert('printers', printer.toMap());
  }

  Future<int> update(Printer printer) async {
    final db = await DBProvider.instance.database;
    if (printer.isDefault) {
      await db.update('printers', {'is_default': 0});
    }
    return db.update(
      'printers',
      printer.toMap(),
      where: 'id = ?',
      whereArgs: [printer.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return db.delete('printers', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setDefault(int id) async {
    final db = await DBProvider.instance.database;
    await db.update('printers', {'is_default': 0});
    await db.update(
      'printers',
      {'is_default': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
