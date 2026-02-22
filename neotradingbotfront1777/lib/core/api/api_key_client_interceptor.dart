import 'package:grpc/grpc.dart';

/// Header name utilizzato per l'API key (deve corrispondere al backend).
const String _apiKeyHeader = 'x-api-key';

/// Interceptor client-side che aggiunge il header `x-api-key` a ogni chiamata gRPC.
///
/// Se [apiKey] è `null` o vuoto, l'interceptor è un no-op.
///
/// Uso in `injection.dart`:
/// ```dart
/// final apiKey = const String.fromEnvironment('GRPC_API_KEY', defaultValue: '');
/// final interceptors = [
///   if (apiKey.isNotEmpty) ApiKeyClientInterceptor(apiKey),
/// ];
/// ```
class ApiKeyClientInterceptor extends ClientInterceptor {
  final String apiKey;

  ApiKeyClientInterceptor(this.apiKey);

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    final newOptions = options.mergedWith(
      CallOptions(metadata: {_apiKeyHeader: apiKey}),
    );
    return invoker(method, request, newOptions);
  }

  @override
  ResponseStream<R> interceptStreaming<Q, R>(
    ClientMethod<Q, R> method,
    Stream<Q> requests,
    CallOptions options,
    ClientStreamingInvoker<Q, R> invoker,
  ) {
    final newOptions = options.mergedWith(
      CallOptions(metadata: {_apiKeyHeader: apiKey}),
    );
    return invoker(method, requests, newOptions);
  }
}
