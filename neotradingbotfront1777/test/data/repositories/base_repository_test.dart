import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotfront1777/core/error/failure.dart';
import 'package:neotradingbotfront1777/data/repositories/base_repository.dart';
import 'dart:async';

class TestRepository extends BaseRepository {}

void main() {
  late TestRepository repository;

  setUp(() {
    repository = TestRepository();
  });

  group('BaseRepository - handleGrpcError', () {
    test('should return Right(data) when operation is successful', () {
      final result = repository.handleGrpcError(() => 'success');
      expect(result, const Right('success'));
    });

    test('should return Left(ServerFailure) when GrpcError occurs', () {
      final result = repository.handleGrpcError(() {
        throw GrpcError.internal('error message');
      });
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(failure.message, contains('error message'));
        expect(failure.message.toUpperCase(), contains('INTERNAL'));
      }, (_) => fail('Should have returned Left'));
    });

    test(
      'should return Left(NotFoundFailure) when GrpcError.notFound occur',
      () {
        // Usiamo esplicitamente StatusCode.notFound
        final result = repository.handleGrpcError(() {
          throw GrpcError.notFound('not found');
        });

        expect(result.fold((l) => l, (r) => r), isA<NotFoundFailure>());
      },
    );

    test('should return Left(UnexpectedFailure) for generic exceptions', () {
      final result = repository.handleGrpcError(() => throw Exception('oops'));
      expect(result.fold((l) => l, (r) => r), isA<UnexpectedFailure>());
    });
  });

  group('BaseRepository - handleAsyncGrpcOperation', () {
    test(
      'should return Right(data) when async operation is successful',
      () async {
        final result = await repository.handleAsyncGrpcOperation(
          () async => 'async success',
        );
        expect(result, const Right('async success'));
      },
    );

    test(
      'should return Left(ServerFailure) when async GrpcError occurs',
      () async {
        final result = await repository.handleAsyncGrpcOperation(() async {
          throw GrpcError.unavailable('offline');
        });
        expect(result.isLeft(), true);
        expect(result.fold((l) => l.message, (r) => null), contains('offline'));
      },
    );
  });

  group('BaseRepository - handleGrpcStream', () {
    test('should map data to Right in stream', () async {
      final stream = Stream.fromIterable(['data1', 'data2']);
      final handledStream = repository.handleGrpcStream(stream);

      final results = await handledStream.toList();
      expect(results, [const Right('data1'), const Right('data2')]);
    });

    test('should map GrpcError to Left(ServerFailure) in stream', () async {
      // In Dart, Stream.error() non emette nulla se handleError cattura l'errore?
      // Usiamo un controller per simulare un errore che capita durante lo stream
      final controller = StreamController<String>();
      final handledStream = repository.handleGrpcStream(controller.stream);

      final results = <Either<Failure, String>>[];
      final subscription = handledStream.listen(results.add);

      controller.addError(GrpcError.aborted('aborted error'));
      await Future.delayed(Duration(milliseconds: 100));
      controller.close();
      await subscription.cancel();

      expect(results.length, 1);
      final emission = results.first;
      expect(emission.isLeft(), true);
      expect(
        emission.fold((l) => l.message, (r) => null),
        contains('aborted error'),
      );
    });
  });
}
