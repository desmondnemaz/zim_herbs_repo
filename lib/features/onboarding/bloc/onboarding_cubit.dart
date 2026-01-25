import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingComplete extends OnboardingState {}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);

  @override
  List<Object?> get props => [message];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingInitial());

  Future<void> completeOnboarding() async {
    emit(OnboardingLoading());
    try {
      final box = await Hive.openBox(SettingsRepository.boxName);
      await box.put('onboarding_done', true);
      emit(OnboardingComplete());
    } catch (e) {
      emit(OnboardingError("Failed to save onboarding status: $e"));
    }
  }
}
