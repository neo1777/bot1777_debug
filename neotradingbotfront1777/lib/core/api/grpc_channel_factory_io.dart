import 'dart:io';
import 'package:grpc/grpc.dart';
import 'grpc_channel_factory.dart';

GrpcChannelFactory createFactory() => IoGrpcChannelFactory();

class IoGrpcChannelFactory implements GrpcChannelFactory {
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
    ChannelCredentials credentials;
    if (secure) {
      if (certificates != null) {
        credentials = ChannelCredentials.secure(
          certificates: certificates,
          authority: authority,
        );
      } else {
        credentials = ChannelCredentials.secure(
          onBadCertificate: (X509Certificate cert, String h) {
            // Verify Hostname
            if (!strictTlsMatch && h == host) return true;

            // Verify Subject
            final subject = cert.subject;
            final subjectOk =
                expectedSubject == null || expectedSubject.isEmpty
                    ? true
                    : (strictTlsMatch
                        ? subject == expectedSubject
                        : subject.contains(expectedSubject));

            // Verify Issuer
            final issuer = cert.issuer;
            final issuerOk =
                expectedIssuer == null || expectedIssuer.isEmpty
                    ? true
                    : (strictTlsMatch
                        ? issuer == expectedIssuer
                        : issuer.contains(expectedIssuer));

            return subjectOk && issuerOk;
          },
        );
      }
    } else {
      credentials = const ChannelCredentials.insecure();
    }

    return ClientChannel(
      host,
      port: port,
      options: ChannelOptions(credentials: credentials),
    );
  }
}
