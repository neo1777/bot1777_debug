import 'grpc_channel_factory.dart';

GrpcChannelFactory createFactory() =>
    throw UnsupportedError(
      'Cannot create a factory without dart:io or dart:html',
    );
