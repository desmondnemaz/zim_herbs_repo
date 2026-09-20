import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/herb.dart';
import '../../domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/entities/remedy.dart';
import 'package:zim_herbs_repo/features/repository/remedies/domain/repositories/remedy_repository.dart';

abstract class HerbDetailState extends Equatable {
  const HerbDetailState();

  @override
  List<Object?> get props => [];
}

class HerbDetailInitial extends HerbDetailState {}

class HerbDetailLoading extends HerbDetailState {}

class HerbDetailLoaded extends HerbDetailState {
  final Herb herb;
  final List<Remedy> remedies;

  /// Backwards-compatible alias for remedies.
  List<Remedy> get treatments => remedies;

  const HerbDetailLoaded({
    required this.herb,
    required this.remedies,
  });

  @override
  List<Object?> get props => [herb, remedies];
}

class HerbDetailError extends HerbDetailState {
  final String message;

  const HerbDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class HerbDetailCubit extends Cubit<HerbDetailState> {
  final HerbRepository _herbRepository;
  final RemedyRepository _remedyRepository;

  HerbDetailCubit({
    required HerbRepository herbRepository,
    required RemedyRepository remedyRepository,
  })  : _herbRepository = herbRepository,
        _remedyRepository = remedyRepository,
        super(HerbDetailInitial());

  Future<void> loadHerb(String id) async {
    emit(HerbDetailLoading());
    try {
      final results = await Future.wait([
        _herbRepository.getHerbById(id),
        _remedyRepository.getRemediesByHerbId(id),
      ]);

      final herb = results[0] as Herb?;
      final remedies = results[1] as List<Remedy>;

      if (herb == null) {
        emit(const HerbDetailError("Herb not found"));
      } else {
        emit(HerbDetailLoaded(herb: herb, remedies: remedies));
      }
    } catch (e) {
      emit(HerbDetailError("Failed to load herb details: $e"));
    }
  }
}
