import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/condition_repository.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';
import 'package:equatable/equatable.dart';

abstract class ConditionDetailState extends Equatable {
  const ConditionDetailState();
  @override
  List<Object?> get props => [];
}

class ConditionDetailInitial extends ConditionDetailState {}

class ConditionDetailLoading extends ConditionDetailState {}

class ConditionDetailLoaded extends ConditionDetailState {
  final ConditionModel condition;
  const ConditionDetailLoaded(this.condition);
  @override
  List<Object?> get props => [condition];
}

class ConditionDetailError extends ConditionDetailState {
  final String message;
  const ConditionDetailError(this.message);
  @override
  List<Object?> get props => [message];
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
        emit(const ConditionDetailError("Condition not found"));
      }
    } catch (e) {
      emit(ConditionDetailError(e.toString()));
    }
  }
}
