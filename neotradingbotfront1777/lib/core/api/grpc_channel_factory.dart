import 'package:grpc/service_api.dart';
import 'grpc_channel_factory_stub.dart'
    if (dart.library.io) 'grpc_channel_factory_io.dart'
    if (dart.library.html) 'grpc_channel_factory_web.dart';

/// Interfaccia astratta per la creazione di canali gRPC in modo platform-aware.
/// Utilizza conditional imports per evitare dipendenze da `dart:io` su Web.
abstract class GrpcChannelFactory {
  static GrpcChannelFactory? _instance;

  static GrpcChannelFactory get instance {
    _instance ??= createFactory();
    return _instance!;
  }

  ClientChannel createChannel({
    required String host,
    required int port,
    bool secure = true,
    List<int>? certificates,
    String? authority,
    String? expectedSubject,
    String? expectedIssuer,
    bool strictTlsMatch = false,
  });
}
