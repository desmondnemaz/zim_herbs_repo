import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/conditions/data/repository/model.dart';

/// Just like in the Herbs feature, these are the "Orders" for the Conditions screen.
abstract class ConditionEvent extends Equatable {
  const ConditionEvent();

  @override
  List<Object?> get props => [];
}

/// Order: "Fetch all conditions from the database please!"
class LoadConditions extends ConditionEvent {}

/// Order: "Filter the conditions based on what the user typed."
class SearchConditions extends ConditionEvent {
  final String query;

  const SearchConditions(this.query);

  @override
  List<Object?> get props => [query];
}

/// Order: "Something changed, please reload the conditions."
class RefreshConditions extends ConditionEvent {}

/// Order: "Create a new condition."
class CreateCondition extends ConditionEvent {
  final ConditionModel condition;
  const CreateCondition(this.condition);

  @override
  List<Object?> get props => [condition];
}

/// Order: "Update an existing condition."
class UpdateCondition extends ConditionEvent {
  final ConditionModel condition;
  const UpdateCondition(this.condition);

  @override
  List<Object?> get props => [condition];
}

/// Order: "Delete a condition."
class DeleteCondition extends ConditionEvent {
  final String id;
  const DeleteCondition(this.id);

  @override
  List<Object?> get props => [id];
}
