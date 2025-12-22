part of 'connection_bloc.dart';

enum ConnectionStatus { initial, online, offline }

class ConnectionState extends Equatable {
  final ConnectionStatus status;

  const ConnectionState({this.status = ConnectionStatus.initial});

  @override
  List<Object> get props => [status];
}
