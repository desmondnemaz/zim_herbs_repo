import 'package:equatable/equatable.dart';

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
