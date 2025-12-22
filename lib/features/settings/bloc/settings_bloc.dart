import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  static const String boxName = 'settings_box';
  static const String fontScaleKey = 'font_scale';

  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateFontScale>(_onUpdateFontScale);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final box = await Hive.openBox(boxName);
    final savedScale = box.get(fontScaleKey, defaultValue: 1.0) as double;

    emit(state.copyWith(fontScale: savedScale));
  }

  Future<void> _onUpdateFontScale(
    UpdateFontScale event,
    Emitter<SettingsState> emit,
  ) async {
    final box = await Hive.openBox(boxName);
    await box.put(fontScaleKey, event.fontScale);
    emit(state.copyWith(fontScale: event.fontScale));
  }
}
