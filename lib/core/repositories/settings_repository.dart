import 'package:isar/isar.dart';
import '../../database/models/settings.dart';

class SettingsRepository {
  Isar get _isar => Isar.getInstance()!;

  Future<void> saveSettings(Settings settings) async {
    await _isar.writeTxn(() async {
      await _isar.settings.put(settings);
    });
  }

  Future<Settings> getSettings() async {
    var settings = await _isar.settings.where().findFirst();
    if (settings == null) {
      settings = Settings();
      await saveSettings(settings);
    }
    return settings;
  }
}
