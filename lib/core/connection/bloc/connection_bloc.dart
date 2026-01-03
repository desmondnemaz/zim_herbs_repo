import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

part 'connection_event.dart';
part 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectionBloc() : super(const ConnectionState()) {
    on<ConnectionListen>(_onListen);
    on<ConnectionChanged>(_onChanged);
  }

  void _onListen(ConnectionListen event, Emitter<ConnectionState> emit) async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result, emit);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      add(ConnectionChanged(results));
    });
  }

  void _onChanged(ConnectionChanged event, Emitter<ConnectionState> emit) {
    _updateStatus(event.results, emit);
  }

  void _updateStatus(
    List<ConnectivityResult> results,
    Emitter<ConnectionState> emit,
  ) {
    // If any of the results is mobile, wifi, or ethernet, we are online.
    // connectivity_plus 6.0 returns a List<ConnectivityResult>.
    final isOnline = results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn ||
          r == ConnectivityResult.other,
    );

    if (isOnline) {
      emit(const ConnectionState(status: ConnectionStatus.online));
    } else {
      emit(const ConnectionState(status: ConnectionStatus.offline));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
