part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final double fontScale;

  const SettingsState({this.fontScale = 1.0});

  SettingsState copyWith({double? fontScale}) {
    return SettingsState(fontScale: fontScale ?? this.fontScale);
  }

  @override
  List<Object> get props => [fontScale];
}
