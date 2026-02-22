import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'package:grpc/grpc.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';

/// FIX BUG #9: Base class per ridurre duplicazione nei repository
/// Fornisce gestione errori comune senza consolidare le responsabilità
abstract class BaseRepository {
  /// Gestisce errori gRPC comuni per tutti i repository
  /// Evita duplicazione del codice di error handling
  Either<Failure, T> handleGrpcError<T>(T Function() operation) {
    try {
      final result = operation();
      return Right(result);
    } on GrpcError catch (e) {
      // Propagazione warnings come successo informativo (code OK con messaggio [WARN])
      if (e.code == StatusCode.ok &&
          (e.message?.startsWith('[WARN]') ?? false)) {
        return Left(UnexpectedFailure(message: e.message ?? 'Avviso'));
      }
      if (e.code == StatusCode.notFound) {
        return const Left(NotFoundFailure(message: 'NOT_FOUND'));
      }
      return Left(
        ServerFailure(
          message: '${e.message ?? 'Errore sconosciuto gRPC'} (${e.codeName})',
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  /// Gestisce operazioni async con gestione errori comune
  Future<Either<Failure, T>> handleAsyncGrpcOperation<T>(
    Future<T> Function() operation,
  ) async {
    try {
      final result = await operation();
      return Right(result);
    } on GrpcError catch (e) {
      if (e.code == StatusCode.notFound) {
        return const Left(NotFoundFailure(message: 'NOT_FOUND'));
      }
      return Left(
        ServerFailure(
          message: '${e.message ?? 'Errore sconosciuto gRPC'} (${e.codeName})',
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure(message: 'Errore imprevisto: $e'));
    }
  }

  /// Helper per stream con gestione errori
  Stream<Either<Failure, T>> handleGrpcStream<T>(Stream<T> stream) {
    return stream.transform(
      StreamTransformer<T, Either<Failure, T>>.fromHandlers(
        handleData: (data, sink) => sink.add(Right(data)),
        handleError: (error, stackTrace, sink) {
          if (error is GrpcError) {
            sink.add(
              Left(
                ServerFailure(
                  message:
                      error.message ?? 'Errore stream gRPC (${error.codeName})',
                ),
              ),
            );
          } else {
            sink.add(
              Left(
                UnexpectedFailure(message: 'Errore stream imprevisto: $error'),
              ),
            );
          }
        },
      ),
    );
  }

  /// Gestisce la sottoscrizione a uno stream gRPC, catturando errori iniziali.
  Either<Failure, Stream<T>> handleStreamGrpcOperation<T>(
    Stream<T> Function() operation,
  ) {
    try {
      final stream = operation();
      return Right(stream);
    } on GrpcError catch (e) {
      return Left(
        ServerFailure(
          message:
              '${e.message ?? 'Errore di sottoscrizione gRPC'} (${e.codeName})',
        ),
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(message: 'Errore di sottoscrizione imprevisto: $e'),
      );
    }
  }
}
