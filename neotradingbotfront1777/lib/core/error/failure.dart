import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

/// Rappresenta un fallimento durante la comunicazione con il server (gRPC).
class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

/// Rappresenta un fallimento generico o imprevisto.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message});
}

/// Fallimento specifico per risorse non trovate (mappa gRPC NOT_FOUND)
class NotFoundFailure extends Failure {
  const NotFoundFailure({required super.message});
}

/// Rappresenta un fallimento di rete o comunicazione (mappa gRPC UNAVAILABLE, DEADLINE_EXCEEDED, etc.)
class NetworkFailure extends Failure {
  final int? statusCode;
  const NetworkFailure({required super.message, this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 'null'];
}

/// Rappresenta un fallimento di validazione (mappa gRPC INVALID_ARGUMENT)
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message});
}
