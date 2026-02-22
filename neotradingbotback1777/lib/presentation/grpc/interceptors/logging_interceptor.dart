import 'dart:async';
import 'package:grpc/grpc.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';

/// Standardized interceptor for gRPC calls to ensure consistent audit logs.
FutureOr<GrpcError?> loggingInterceptor(
    ServiceCall call, ServiceMethod method) {
  final log = LogManager.getLogger();

  // Log the incoming call with essential metadata
  final client = call.clientMetadata?[':authority'] ?? 'unknown';
  final remoteAddress = call.clientMetadata?[':remote-address'] ?? 'unknown';

  log.i(
      'gRPC Call | Method: ${method.name} | Client: $client | Remote: $remoteAddress');

  return null;
}
