part of 'treatment_bloc.dart';

abstract class TreatmentEvent extends Equatable {
  const TreatmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadTreatments extends TreatmentEvent {}

class SearchTreatments extends TreatmentEvent {
  final String query;
  const SearchTreatments(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterTreatmentsByCondition extends TreatmentEvent {
  final String? conditionId; // Null implies "All"
  const FilterTreatmentsByCondition(this.conditionId);

  @override
  List<Object?> get props => [conditionId];
}

class RefreshTreatments extends TreatmentEvent {}

class DeleteTreatment extends TreatmentEvent {
  final String id;
  const DeleteTreatment(this.id);

  @override
  List<Object?> get props => [id];
}

class ApproveTreatment extends TreatmentEvent {
  final String id;
  final bool approved;
  const ApproveTreatment(this.id, this.approved);

  @override
  List<Object?> get props => [id, approved];
}
