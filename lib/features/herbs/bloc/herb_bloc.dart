import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/data/models.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:zim_herbs_repo/features/herbs/bloc/herb_event.dart';
import 'package:zim_herbs_repo/features/herbs/bloc/herb_state.dart';

/// The BLoC is the "Chef" of the screen.
/// It takes an Event (Order), talks to the Repository (Pantry),
/// and returns a State (Meal).
class HerbBloc extends Bloc<HerbEvent, HerbState> {
  final HerbRepository _repository;
  List<HerbModel> _allHerbs = [];

  // We start the "Chef" with an Initial State
  HerbBloc(this._repository) : super(HerbInitial()) {
    // Here we tell the Bloc: "When you receive this EVENT, run this FUNCTION"
    on<LoadHerbs>(_onLoadHerbs);
    on<SearchHerbs>(_onSearchHerbs);
    on<RefreshHerbs>(_onRefreshHerbs);
  }

  /// This function runs when the UI says "LoadHerbs"
  Future<void> _onLoadHerbs(LoadHerbs event, Emitter<HerbState> emit) async {
    // 1. Tell the UI we are busy (Loading)
    emit(HerbLoading());

    try {
      // 2. Go to the database and get the herbs
      _allHerbs = await _repository.getAllHerbs();

      // 3. Success! Send the herbs back to the UI (Loaded)
      emit(HerbLoaded(_allHerbs));
    } catch (e) {
      // 4. Oops! Something failed. Tell the UI what happened (Error)
      emit(HerbError("Failed to load herbs: $e"));
    }
  }

  /// This function runs when the user types in the search bar
  Future<void> _onSearchHerbs(
    SearchHerbs event,
    Emitter<HerbState> emit,
  ) async {
    try {
      // If we don't have herbs yet, load them first
      if (_allHerbs.isEmpty) {
        _allHerbs = await _repository.getAllHerbs();
      }

      final query = event.query.toLowerCase();

      // If query is empty, show everything
      if (query.isEmpty) {
        emit(HerbLoaded(_allHerbs, searchQuery: ""));
        return;
      }

      // Filter them based on the query the user typed
      final filtered =
          _allHerbs.where((herb) {
            final name = herb.nameEn.toLowerCase();
            final shona = herb.nameSn?.toLowerCase() ?? "";
            final ndebele = herb.nameNd?.toLowerCase() ?? "";
            return name.contains(query) ||
                shona.contains(query) ||
                ndebele.contains(query);
          }).toList();

      // Send the filtered list back to the UI
      emit(HerbLoaded(filtered, searchQuery: event.query));
    } catch (e) {
      emit(HerbError("Search failed: $e"));
    }
  }

  /// Just a simple way to reload everything
  Future<void> _onRefreshHerbs(
    RefreshHerbs event,
    Emitter<HerbState> emit,
  ) async {
    await _onLoadHerbs(LoadHerbs(), emit);
  }
}
