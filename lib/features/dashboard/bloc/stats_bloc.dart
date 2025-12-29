import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/condition_repository.dart';

// Events
abstract class StatsEvent {}

class FetchStats extends StatsEvent {}

// States
abstract class StatsState {}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final int herbCount;
  final int treatmentCount;
  final int conditionCount;

  StatsLoaded({
    required this.herbCount,
    required this.treatmentCount,
    required this.conditionCount,
  });
}

class StatsError extends StatsState {
  final String message;
  StatsError(this.message);
}

// BLoC
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  final HerbRepository herbRepository;
  final TreatmentRepository treatmentRepository;
  final ConditionRepository conditionRepository;

  StatsBloc({
    required this.herbRepository,
    required this.treatmentRepository,
    required this.conditionRepository,
  }) : super(StatsInitial()) {
    on<FetchStats>((event, emit) async {
      emit(StatsLoading());
      try {
        final results = await Future.wait([
          herbRepository.getHerbsCount(),
          treatmentRepository.getTreatmentsCount(),
          conditionRepository.getConditionsCount(),
        ]);

        emit(
          StatsLoaded(
            herbCount: results[0],
            treatmentCount: results[1],
            conditionCount: results[2],
          ),
        );
      } catch (e) {
        emit(StatsError(e.toString()));
      }
    });
  }
}
