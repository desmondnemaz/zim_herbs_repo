import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/errors/error_handler.dart';
import 'package:zim_herbs_repo/features/marketplace/store/data/repository/store_repository.dart';
import 'store_event.dart';
import 'store_state.dart';

class StoreBloc extends Bloc<StoreEvent, StoreState> {
  final StoreRepository _repository;

  StoreBloc(this._repository) : super(StoreInitial()) {
    on<FetchProducts>(_onFetchProducts);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<StoreState> emit,
  ) async {
    emit(StoreLoading());
    try {
      final products = await _repository.getProducts(category: event.category);
      emit(StoreLoaded(products, selectedCategory: event.category));
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handle(e, stackTrace);
      emit(StoreError(failure.message, failure: failure));
    }
  }
}
