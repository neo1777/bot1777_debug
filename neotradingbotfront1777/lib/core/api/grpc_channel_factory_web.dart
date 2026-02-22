import 'package:grpc/service_api.dart';
import 'package:grpc/grpc_web.dart';
import 'grpc_channel_factory.dart';

GrpcChannelFactory createFactory() => WebGrpcChannelFactory();

class WebGrpcChannelFactory implements GrpcChannelFactory {
  @override
  ClientChannel createChannel({
    required String host,
    required int port,
    bool secure = true,
    List<int>? certificates,
    String? authority,
    String? expectedSubject,
    String? expectedIssuer,
    bool strictTlsMatch = false,
  }) {
    // In gRPC-Web, TLS is managed by the browser (HTTPS).
    // The 'secure' flag simply changes the protocol to https://.
    // Certificates and manual verification are not supported directly in the browser.

    final protocol = secure ? 'https' : 'http';
    final uri = Uri.parse('$protocol://$host:$port');

    return GrpcWebClientChannel.xhr(uri);
  }
}
