import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_models.dart';
import 'package:zim_herbs_repo/features/treatments/data/treatment_repository.dart';

abstract class HerbDetailState extends Equatable {
  const HerbDetailState();

  @override
  List<Object?> get props => [];
}

class HerbDetailInitial extends HerbDetailState {}

class HerbDetailLoading extends HerbDetailState {}

class HerbDetailLoaded extends HerbDetailState {
  final HerbModel herb;
  final List<TreatmentModel> treatments;

  const HerbDetailLoaded({required this.herb, required this.treatments});

  @override
  List<Object?> get props => [herb, treatments];
}

class HerbDetailError extends HerbDetailState {
  final String message;

  const HerbDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class HerbDetailCubit extends Cubit<HerbDetailState> {
  final HerbRepository _herbRepository;
  final TreatmentRepository _treatmentRepository;

  HerbDetailCubit({
    required HerbRepository herbRepository,
    required TreatmentRepository treatmentRepository,
  }) : _herbRepository = herbRepository,
       _treatmentRepository = treatmentRepository,
       super(HerbDetailInitial());

  Future<void> loadHerb(String id) async {
    emit(HerbDetailLoading());
    try {
      final results = await Future.wait([
        _herbRepository.getHerbById(id),
        _treatmentRepository.getTreatmentsByHerbId(id),
      ]);

      final herb = results[0] as HerbModel?;
      final treatments = results[1] as List<TreatmentModel>;

      if (herb == null) {
        emit(const HerbDetailError("Herb not found"));
      } else {
        emit(HerbDetailLoaded(herb: herb, treatments: treatments));
      }
    } catch (e) {
      emit(HerbDetailError("Failed to load herb details: $e"));
    }
  }
}
