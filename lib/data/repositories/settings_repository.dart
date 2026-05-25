import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/settings.dart';

class SettingsRepository {
  Future<Settings?> load() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query('settings', limit: 1);
    if (maps.isEmpty) {
      return null;
    }
    return Settings.fromMap(maps.first);
  }

  Future<int> save(Settings settings) async {
    final db = await DBProvider.instance.database;
    if (settings.id != null) {
      return await db.update(
        'settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id],
      );
    }
    return await db.insert('settings', settings.toMap());
  }
}
