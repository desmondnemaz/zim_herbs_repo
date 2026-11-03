import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import '../../domain/entities/ailment.dart';
import '../../domain/repositories/ailment_repository.dart';

abstract class AilmentDetailState extends Equatable {
  const AilmentDetailState();
  @override
  List<Object?> get props => [];
}

class AilmentDetailInitial extends AilmentDetailState {}

class AilmentDetailLoading extends AilmentDetailState {}

class AilmentDetailLoaded extends AilmentDetailState {
  final Ailment ailment;
  const AilmentDetailLoaded(this.ailment);

  /// Backward-compatible alias
  Ailment get condition => ailment;

  @override
  List<Object?> get props => [ailment];
}

class AilmentDetailError extends AilmentDetailState {
  final String message;
  final Failure? failure;

  const AilmentDetailError(this.message, {this.failure});

  @override
  List<Object?> get props => [message, failure];
}

class AilmentDetailCubit extends Cubit<AilmentDetailState> {
  final AilmentRepository _repository;

  AilmentDetailCubit(this._repository) : super(AilmentDetailInitial());

  Future<void> loadAilment(String id) async {
    emit(AilmentDetailLoading());
    try {
      final ailment = await _repository.getAilmentById(id);
      if (ailment != null) {
        emit(AilmentDetailLoaded(ailment));
      } else {
        emit(const AilmentDetailError(
          "Ailment not found",
          failure: Failure(
            title: "Ailment Not Found",
            message: "The requested medical ailment could not be found.",
            type: FailureType.notFound,
          ),
        ));
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(AilmentDetailError(failure.message, failure: failure));
    }
  }

  /// Backward-compatible alias
  Future<void> loadCondition(String id) => loadAilment(id);
}

// ============================================================
// BACKWARD-COMPATIBLE ALIASES
// ============================================================
typedef ConditionDetailCubit = AilmentDetailCubit;
typedef ConditionDetailState = AilmentDetailState;
typedef ConditionDetailInitial = AilmentDetailInitial;
typedef ConditionDetailLoading = AilmentDetailLoading;
typedef ConditionDetailLoaded = AilmentDetailLoaded;
typedef ConditionDetailError = AilmentDetailError;
