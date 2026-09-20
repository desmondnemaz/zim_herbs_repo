import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/repositories/remedy_repository.dart';
import 'package:zim_herbs_repo/features/repository/conditions/domain/repositories/condition_repository.dart';

// Events
abstract class StatsEvent {}

class FetchStats extends StatsEvent {}

// States
abstract class StatsState {}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final int herbCount;
  final int remedyCount;
  final int conditionCount;

  /// Backwards-compatible alias for remedyCount.
  int get treatmentCount => remedyCount;

  StatsLoaded({
    required this.herbCount,
    required this.remedyCount,
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
  final RemedyRepository remedyRepository;
  final ConditionRepository conditionRepository;

  StatsBloc({
    required this.herbRepository,
    required this.remedyRepository,
    required this.conditionRepository,
  }) : super(StatsInitial()) {
    on<FetchStats>((event, emit) async {
      emit(StatsLoading());
      try {
        final results = await Future.wait([
          herbRepository.getHerbsCount(),
          remedyRepository.getRemediesCount(),
          conditionRepository.getConditionsCount(),
        ]);

        emit(
          StatsLoaded(
            herbCount: results[0],
            remedyCount: results[1],
            conditionCount: results[2],
          ),
        );
      } catch (e) {
        emit(StatsError(e.toString()));
      }
    });
  }
}
