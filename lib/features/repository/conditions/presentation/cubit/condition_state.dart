import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/condition.dart';

abstract class ConditionState {}

class ConditionInitial extends ConditionState {}

class ConditionLoading extends ConditionState {}

class ConditionLoaded extends ConditionState {
  final List<Condition> conditions;
  final String searchQuery;
  final BodySystem? selectedBodySystem;

  ConditionLoaded(
    this.conditions, {
    this.searchQuery = '',
    this.selectedBodySystem,
  });
}

class ConditionError extends ConditionState {
  final String message;

  ConditionError(this.message);
}

class ConditionOperationSuccess extends ConditionState {
  final String message;

  ConditionOperationSuccess(this.message);
}
