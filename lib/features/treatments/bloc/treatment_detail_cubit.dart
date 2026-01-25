import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';
import 'package:equatable/equatable.dart';

abstract class TreatmentDetailState extends Equatable {
  const TreatmentDetailState();
  @override
  List<Object?> get props => [];
}

class TreatmentDetailInitial extends TreatmentDetailState {}

class TreatmentDetailLoading extends TreatmentDetailState {}

class TreatmentDetailLoaded extends TreatmentDetailState {
  final TreatmentModel treatment;
  const TreatmentDetailLoaded(this.treatment);
  @override
  List<Object?> get props => [treatment];
}

class TreatmentDetailError extends TreatmentDetailState {
  final String message;
  const TreatmentDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class TreatmentDetailCubit extends Cubit<TreatmentDetailState> {
  final TreatmentRepository _repository;

  TreatmentDetailCubit(this._repository) : super(TreatmentDetailInitial());

  Future<void> loadTreatment(String id) async {
    emit(TreatmentDetailLoading());
    try {
      final treatment = await _repository.getTreatmentById(id);
      if (treatment != null) {
        emit(TreatmentDetailLoaded(treatment));
      } else {
        emit(const TreatmentDetailError("Treatment not found"));
      }
    } catch (e) {
      emit(TreatmentDetailError(e.toString()));
    }
  }
}
