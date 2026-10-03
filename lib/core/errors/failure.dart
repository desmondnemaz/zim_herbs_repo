import 'package:equatable/equatable.dart';

enum FailureType {
  noInternet,
  serverUnavailable,
  timeout,
  invalidCredentials,
  userNotFound,
  userAlreadyExists,
  weakPassword,
  emailNotConfirmed,
  tooManyRequests,
  accessDenied,
  validation,
  notFound,
  unknown,
}

class Failure extends Equatable {
  final String message;
  final String? title;
  final FailureType type;
  final Object? originalError;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.title,
    this.type = FailureType.unknown,
    this.originalError,
    this.stackTrace,
  });

  bool get isNetworkError =>
      type == FailureType.noInternet ||
      type == FailureType.timeout ||
      type == FailureType.serverUnavailable;

  bool get isServerError => type == FailureType.serverUnavailable;

  bool get isAuthCredentialError =>
      type == FailureType.invalidCredentials ||
      type == FailureType.userNotFound ||
      type == FailureType.accessDenied;

  @override
  List<Object?> get props => [message, title, type];

  @override
  String toString() => 'Failure(type: $type, title: $title, message: $message)';
}
