import 'package:zim_herbs_repo/core/errors/failure.dart';
import 'package:zim_herbs_repo/core/utils/enums.dart';
import '../../domain/entities/ailment.dart';
import '../../domain/entities/body_part.dart';

abstract class AilmentState {}

class AilmentInitial extends AilmentState {}

class AilmentLoading extends AilmentState {}

class AilmentLoaded extends AilmentState {
  final List<Ailment> ailments;
  final List<BodyPart> allBodyParts;
  final String searchQuery;
  final AilmentCategory? selectedAilmentCategory;
  final String? selectedBodyPartId;

  /// Backward-compatible aliases
  List<Ailment> get conditions => ailments;
  AilmentCategory? get selectedBodySystem => selectedAilmentCategory;

  AilmentLoaded(
    this.ailments, {
    this.allBodyParts = const [],
    this.searchQuery = '',
    AilmentCategory? selectedAilmentCategory,
    AilmentCategory? selectedBodySystem,
    this.selectedBodyPartId,
  }) : selectedAilmentCategory = selectedAilmentCategory ?? selectedBodySystem;
}

class AilmentError extends AilmentState {
  final String message;
  final Failure? failure;

  AilmentError(this.message, {this.failure});
}

class AilmentOperationSuccess extends AilmentState {
  final String message;

  AilmentOperationSuccess(this.message);
}

// ============================================================
// BACKWARD-COMPATIBLE ALIASES
// ============================================================
typedef ConditionState = AilmentState;
typedef ConditionInitial = AilmentInitial;
typedef ConditionLoading = AilmentLoading;
typedef ConditionLoaded = AilmentLoaded;
typedef ConditionError = AilmentError;
typedef ConditionOperationSuccess = AilmentOperationSuccess;
