part of 'treatment_bloc.dart';

abstract class TreatmentState extends Equatable {
  const TreatmentState();

  @override
  List<Object?> get props => [];
}

class TreatmentInitial extends TreatmentState {}

class TreatmentLoading extends TreatmentState {}

class TreatmentLoaded extends TreatmentState {
  final List<TreatmentModel> treatments;
  final String searchQuery;

  const TreatmentLoaded(this.treatments, {this.searchQuery = ''});

  @override
  List<Object?> get props => [treatments, searchQuery];
}

class TreatmentError extends TreatmentState {
  final String message;
  const TreatmentError(this.message);

  @override
  List<Object?> get props => [message];
}
