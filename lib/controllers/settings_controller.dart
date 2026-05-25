import 'package:get/get.dart';
import 'package:abpos/data/repositories/settings_repository.dart';
import 'package:abpos/models/settings.dart';

class SettingsController extends GetxController {
  final SettingsRepository _repository = SettingsRepository();
  final Rx<Settings?> settings = Rx<Settings?>(null);

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    settings.value = await _repository.load();
  }

  Future<void> saveSettings(Settings newSettings) async {
    await _repository.save(newSettings);
    settings.value = newSettings;
  }
}
