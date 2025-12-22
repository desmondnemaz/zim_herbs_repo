import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';

/// These are the "Results" or "Snapshots" sent from the Chef (Bloc) to the UI.
abstract class ConditionState extends Equatable {
  const ConditionState();

  @override
  List<Object?> get props => [];
}

/// 1. Initial State: Screen just opened.
class ConditionInitial extends ConditionState {}

/// 2. Loading State: Talking to Supabase.
class ConditionLoading extends ConditionState {}

/// 3. Loaded State: We have the conditions!
class ConditionLoaded extends ConditionState {
  final List<ConditionModel> conditions;
  final String searchQuery;

  const ConditionLoaded(this.conditions, {this.searchQuery = ""});

  @override
  List<Object?> get props => [conditions, searchQuery];
}

/// 4. Error State: Something went wrong.
class ConditionError extends ConditionState {
  final String message;

  const ConditionError(this.message);

  @override
  List<Object?> get props => [message];
}
