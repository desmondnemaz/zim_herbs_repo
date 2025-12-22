part of 'connection_bloc.dart';

abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object> get props => [];
}

class ConnectionListen extends ConnectionEvent {}

class ConnectionChanged extends ConnectionEvent {
  final List<ConnectivityResult> results;

  const ConnectionChanged(this.results);

  @override
  List<Object> get props => [results];
}
