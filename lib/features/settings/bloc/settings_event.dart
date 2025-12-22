part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class LoadSettings extends SettingsEvent {}

class UpdateFontScale extends SettingsEvent {
  final double fontScale;

  const UpdateFontScale(this.fontScale);

  @override
  List<Object> get props => [fontScale];
}
