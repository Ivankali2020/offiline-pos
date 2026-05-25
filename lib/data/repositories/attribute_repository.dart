import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/attribute.dart';
import 'package:abpos/models/attribute_value.dart';

class AttributeRepository {
  Future<List<Attribute>> findAll() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('attributes', orderBy: 'name ASC');
    return maps.map((map) => Attribute.fromMap(map)).toList();
  }

  Future<List<AttributeValue>> findValuesByAttributeId(int attributeId) async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'attribute_values',
      where: 'attribute_id = ?',
      whereArgs: [attributeId],
      orderBy: 'value ASC',
    );
    return maps.map((map) => AttributeValue.fromMap(map)).toList();
  }

  Future<int> insert(Attribute attribute) async {
    final db = await DBProvider.instance.database;
    return await db.insert('attributes', attribute.toMap());
  }

  Future<int> update(Attribute attribute) async {
    final db = await DBProvider.instance.database;
    return await db.update(
      'attributes',
      attribute.toMap(),
      where: 'id = ?',
      whereArgs: [attribute.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await DBProvider.instance.database;
    return await db.transaction((txn) async {
      await txn.delete(
        'attribute_values',
        where: 'attribute_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('attributes', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> insertValue(AttributeValue value) async {
    final db = await DBProvider.instance.database;
    return await db.insert('attribute_values', value.toMap());
  }

  Future<int> updateValue(AttributeValue value) async {
    final db = await DBProvider.instance.database;
    return await db.update(
      'attribute_values',
      value.toMap(),
      where: 'id = ?',
      whereArgs: [value.id],
    );
  }

  Future<int> deleteValue(int id) async {
    final db = await DBProvider.instance.database;
    return await db.delete(
      'attribute_values',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
