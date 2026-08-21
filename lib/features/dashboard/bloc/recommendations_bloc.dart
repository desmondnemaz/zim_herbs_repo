import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/entities/herb.dart';
import 'package:zim_herbs_repo/features/repository/herbs/domain/repositories/herb_repository.dart';
import 'package:zim_herbs_repo/features/marketplace/store/data/models/product_model.dart';
import 'package:zim_herbs_repo/features/marketplace/store/data/repository/store_repository.dart';

// Events
abstract class RecommendationsEvent {}

class FetchRecommendations extends RecommendationsEvent {}

// States
abstract class RecommendationsState {}

class RecommendationsInitial extends RecommendationsState {}

class RecommendationsLoading extends RecommendationsState {}

class RecommendationsLoaded extends RecommendationsState {
  final List<Herb> trendingHerbs;
  final List<Herb> newRepoHerbs;
  final List<ProductModel> newStoreProducts;

  RecommendationsLoaded({
    required this.trendingHerbs,
    required this.newRepoHerbs,
    required this.newStoreProducts,
  });
}

class RecommendationsError extends RecommendationsState {
  final String message;
  RecommendationsError(this.message);
}

// BLoC
class RecommendationsBloc extends Bloc<RecommendationsEvent, RecommendationsState> {
  final HerbRepository herbRepository;
  final StoreRepository storeRepository;

  RecommendationsBloc({
    required this.herbRepository,
    required this.storeRepository,
  }) : super(RecommendationsInitial()) {
    on<FetchRecommendations>((event, emit) async {
      emit(RecommendationsLoading());
      try {
        final results = await Future.wait([
          herbRepository.getTrendingHerbs(limit: 5),
          herbRepository.getLatestHerbs(limit: 5),
          storeRepository.getLatestProducts(limit: 5),
        ]);

        emit(
          RecommendationsLoaded(
            trendingHerbs: results[0] as List<Herb>,
            newRepoHerbs: results[1] as List<Herb>,
            newStoreProducts: results[2] as List<ProductModel>,
          ),
        );
      } catch (e) {
        emit(RecommendationsError(e.toString()));
      }
    });
  }
}
