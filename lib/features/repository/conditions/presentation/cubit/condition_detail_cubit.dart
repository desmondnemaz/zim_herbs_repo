import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/core/errors/failure.dart';
import '../../domain/entities/condition.dart';
import '../../domain/repositories/condition_repository.dart';

abstract class ConditionDetailState extends Equatable {
  const ConditionDetailState();
  @override
  List<Object?> get props => [];
}

class ConditionDetailInitial extends ConditionDetailState {}

class ConditionDetailLoading extends ConditionDetailState {}

class ConditionDetailLoaded extends ConditionDetailState {
  final Condition condition;
  const ConditionDetailLoaded(this.condition);
  @override
  List<Object?> get props => [condition];
}

class ConditionDetailError extends ConditionDetailState {
  final String message;
  final Failure? failure;

  const ConditionDetailError(this.message, {this.failure});

  @override
  List<Object?> get props => [message, failure];
}

class ConditionDetailCubit extends Cubit<ConditionDetailState> {
  final ConditionRepository _repository;

  ConditionDetailCubit(this._repository) : super(ConditionDetailInitial());

  Future<void> loadCondition(String id) async {
    emit(ConditionDetailLoading());
    try {
      final condition = await _repository.getConditionById(id);
      if (condition != null) {
        emit(ConditionDetailLoaded(condition));
      } else {
        emit(const ConditionDetailError(
          "Condition not found",
          failure: Failure(
            title: "Condition Not Found",
            message: "The requested medical condition could not be found.",
            type: FailureType.notFound,
          ),
        ));
      }
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(ConditionDetailError(failure.message, failure: failure));
    }
  }
}
