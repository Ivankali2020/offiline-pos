import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/models/export_log.dart';
import 'package:abpos/models/import_log.dart';

class BackupRepository {
  Future<List<ExportLog>> findExports() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'exports',
      orderBy: 'COALESCE(completed_at, created_at) DESC, id DESC',
      limit: 20,
    );
    return maps.map((map) => ExportLog.fromMap(map)).toList();
  }

  Future<List<ImportLog>> findImports() async {
    final db = await DBProvider.instance.database;
    final maps = await db.query(
      'imports',
      orderBy: 'COALESCE(completed_at, created_at) DESC, id DESC',
      limit: 20,
    );
    return maps.map((map) => ImportLog.fromMap(map)).toList();
  }
}
