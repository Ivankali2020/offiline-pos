import 'package:abpos/data/local/db_provider.dart';
import 'package:abpos/data/repositories/backup_repository.dart';
import 'package:abpos/models/export_log.dart';
import 'package:abpos/models/import_log.dart';
import 'package:abpos/services/app_refresh_service.dart';
import 'package:get/get.dart';

class BackupController extends GetxController {
  final BackupRepository _repository = BackupRepository();

  final RxList<ExportLog> exports = <ExportLog>[].obs;
  final RxList<ImportLog> imports = <ImportLog>[].obs;
  final RxBool isBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    exports.assignAll(await _repository.findExports());
    imports.assignAll(await _repository.findImports());
  }

  Future<String> exportBackup() async {
    isBusy.value = true;
    try {
      final path = await DBProvider.instance.exportDatabaseBackup();
      await loadHistory();
      return path;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> importBackup(String sourcePath) async {
    isBusy.value = true;
    try {
      await DBProvider.instance.importDatabaseBackup(sourcePath);
      await AppRefreshService.refreshAll();
      await loadHistory();
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> resetAllData() async {
    isBusy.value = true;
    try {
      await DBProvider.instance.resetDatabaseToDefaults();
      await AppRefreshService.refreshAll();
      await loadHistory();
    } finally {
      isBusy.value = false;
    }
  }
}
