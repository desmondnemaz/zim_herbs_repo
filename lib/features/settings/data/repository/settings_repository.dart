import 'package:hive/hive.dart';

class SettingsRepository {
  static const String boxName = 'settings_box';
  static const String fontScaleKey = 'font_scale';

  Future<double> getFontScale() async {
    final box = await Hive.openBox(boxName);
    return box.get(fontScaleKey, defaultValue: 1.0) as double;
  }

  Future<void> saveFontScale(double scale) async {
    final box = await Hive.openBox(boxName);
    await box.put(fontScaleKey, scale);
  }
}
