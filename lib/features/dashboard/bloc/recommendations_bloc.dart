import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/store/data/models/product_model.dart';
import 'package:zim_herbs_repo/features/store/data/repository/store_repository.dart';

// Events
abstract class RecommendationsEvent {}

class FetchRecommendations extends RecommendationsEvent {}

// States
abstract class RecommendationsState {}

class RecommendationsInitial extends RecommendationsState {}

class RecommendationsLoading extends RecommendationsState {}

class RecommendationsLoaded extends RecommendationsState {
  final List<HerbModel> trendingHerbs;
  final List<HerbModel> newRepoHerbs;
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
            trendingHerbs: results[0] as List<HerbModel>,
            newRepoHerbs: results[1] as List<HerbModel>,
            newStoreProducts: results[2] as List<ProductModel>,
          ),
        );
      } catch (e) {
        emit(RecommendationsError(e.toString()));
      }
    });
  }
}
