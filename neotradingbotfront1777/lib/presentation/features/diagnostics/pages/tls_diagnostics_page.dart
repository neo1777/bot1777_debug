import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/api/grpc_client.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/gradient_icon_container.dart';
import 'package:neotradingbotfront1777/presentation/common_widgets/main_shell.dart';
import 'package:neotradingbotfront1777/data/datasources/i_trading_remote_datasource.dart';

class TlsDiagnosticsPage extends StatefulWidget {
  const TlsDiagnosticsPage({super.key});

  @override
  State<TlsDiagnosticsPage> createState() => _TlsDiagnosticsPageState();
}

class _TlsDiagnosticsPageState extends State<TlsDiagnosticsPage> {
  late GrpcConnectionStatus _status;

  @override
  void initState() {
    super.initState();
    _status = sl<GrpcClientManager>().currentStatus;
    sl<GrpcClientManager>().statusStream.listen((s) {
      if (!mounted) return;
      setState(() => _status = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final certAsset = const String.fromEnvironment(
      'GRPC_TLS_CERT_ASSET',
      defaultValue: '',
    );
    final certB64 = const String.fromEnvironment(
      'GRPC_TLS_CERT_B64',
      defaultValue: '',
    );
    final serverName = const String.fromEnvironment(
      'GRPC_TLS_SERVER_NAME',
      defaultValue: '',
    );
    final tlsSubject = const String.fromEnvironment(
      'TLS_SUBJECT',
      defaultValue: '',
    );
    final tlsIssuer = const String.fromEnvironment(
      'TLS_ISSUER',
      defaultValue: '',
    );
    final allowInsecure = const bool.fromEnvironment(
      'GRPC_ALLOW_INSECURE',
      defaultValue: false,
    );
    final host = const String.fromEnvironment('GRPC_HOST', defaultValue: '');
    final port = const int.fromEnvironment('GRPC_PORT', defaultValue: 8080);

    // In configureDependencies() il client viene inizializzato con secure=true,
    // e in GrpcClientManager, in release si forza TLS.
    // P17 fix: calcolo dinamico basato su environment e release mode
    final inferredSecureRequested = kReleaseMode || !allowInsecure;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading:
            MediaQuery.of(context).size.width <= 768
                ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed:
                      () =>
                          MainShell.mobileScaffoldKey.currentState
                              ?.openDrawer(),
                )
                : null,
        title: Row(
          children: [
            const GradientIconContainer(icon: Icons.security),
            const SizedBox(width: 12),
            Text(
              'DIAGNOSTICA TLS / gRPC',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Stato connessione'),
          _kv('Connection Status', _status.name.toUpperCase()),
          _kv('kReleaseMode', kReleaseMode.toString()),
          const SizedBox(height: 16),

          _sectionTitle('Server Stats'),
          _ServerStatsWidget(),
          const SizedBox(height: 16),

          _sectionTitle('Parametri gRPC'),
          _kv('Host', host.isEmpty ? '(default runtime)' : host),
          _kv('Port', port.toString()),
          _kv('Secure richiesto (app)', inferredSecureRequested.toString()),
          _kv('GRPC_ALLOW_INSECURE', allowInsecure.toString()),
          const SizedBox(height: 16),
          _sectionTitle('TLS / Pinning'),
          _kv(
            'GRPC_TLS_CERT_ASSET',
            certAsset.isNotEmpty ? certAsset : '(non configurato)',
          ),
          _kv(
            'GRPC_TLS_CERT_B64',
            certB64.isNotEmpty ? '(presente)' : '(non configurato)',
          ),
          _kv(
            'GRPC_TLS_SERVER_NAME',
            serverName.isNotEmpty ? serverName : '(non configurato)',
          ),
          _kv(
            'TLS_SUBJECT',
            tlsSubject.isNotEmpty ? tlsSubject : '(non configurato)',
          ),
          _kv(
            'TLS_ISSUER',
            tlsIssuer.isNotEmpty ? tlsIssuer : '(non configurato)',
          ),
          const SizedBox(height: 16),
          _hintBox(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedTextColor,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Suggerimento: in build di release, TLS è obbligatorio. \n'
        'Per ambienti di sviluppo, è possibile usare certificati self-signed tramite GRPC_TLS_CERT_ASSET o GRPC_TLS_CERT_B64, oppure configurare TLS_SUBJECT/TLS_ISSUER per il pinning. \n'
        'GRPC_ALLOW_INSECURE=false è raccomandato in quasi tutti i contesti.',
        style: TextStyle(color: AppTheme.textColor),
      ),
    );
  }
}

class _ServerStatsWidget extends StatefulWidget {
  @override
  State<_ServerStatsWidget> createState() => _ServerStatsWidgetState();
}

class _ServerStatsWidgetState extends State<_ServerStatsWidget> {
  String _stats = 'Premi refresh per caricare';
  bool _loading = false;

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final result = await sl<ITradingRemoteDatasource>().getWebSocketStats();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold(
        (l) => _stats = 'Errore: ${l.message}',
        (r) => _stats = r.message,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('WebSocket & System Stats'),
                IconButton(
                  icon:
                      _loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.refresh),
                  onPressed: _loading ? null : _loadStats,
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              _stats,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
