import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';

class SettingsState extends Equatable {
  final double fontScale;
  final bool isLoading;

  const SettingsState({this.fontScale = 1.0, this.isLoading = false});

  @override
  List<Object?> get props => [fontScale, isLoading];

  SettingsState copyWith({double? fontScale, bool? isLoading}) {
    return SettingsState(
      fontScale: fontScale ?? this.fontScale,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository _repository;

  SettingsCubit(this._repository) : super(const SettingsState());

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    final fontScale = await _repository.getFontScale();
    emit(state.copyWith(fontScale: fontScale, isLoading: false));
  }

  Future<void> updateFontScale(double scale) async {
    await _repository.saveFontScale(scale);
    emit(state.copyWith(fontScale: scale));
  }
}
