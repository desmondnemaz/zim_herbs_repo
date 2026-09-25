import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/body_part.dart';
import '../../domain/entities/condition.dart';

abstract class ConditionState {}

class ConditionInitial extends ConditionState {}

class ConditionLoading extends ConditionState {}

class ConditionLoaded extends ConditionState {
  final List<Condition> conditions;
  final List<BodyPart> allBodyParts;
  final String searchQuery;
  final BodySystem? selectedBodySystem;
  final String? selectedBodyPartId;

  ConditionLoaded(
    this.conditions, {
    this.allBodyParts = const [],
    this.searchQuery = '',
    this.selectedBodySystem,
    this.selectedBodyPartId,
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
