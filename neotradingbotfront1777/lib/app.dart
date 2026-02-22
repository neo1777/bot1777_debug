import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';
import 'package:neotradingbotfront1777/core/api/grpc_client.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';
// Bloc globali forniti dalla ShellRoute, non più necessari qui
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_bloc.dart'
    as features_th;
import 'package:neotradingbotfront1777/presentation/features/trade_history/bloc/trade_history_event.dart'
    as features_th_events;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Chiusura pulita del canale gRPC all'uscita dell'app
    sl<GrpcClientManager>().shutdown();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Best-effort: chiudi il canale quando l'app è sospesa per lunghi periodi
    if (state == AppLifecycleState.detached) {
      sl<GrpcClientManager>().shutdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Manteniamo a livello applicativo solo i bloc necessari globalmente.
        // Gli altri BLoC specifici di feature vengono forniti dalla ShellRoute in app_router.dart
        // Rimuoviamo SettingsBloc da qui per evitare conflitti con i provider locali
        // BlocProvider(create: (_) => sl<SettingsBloc>()),
        // Fallback provider per TradeHistoryBloc per i widget del dashboard che ne fanno uso diretto
        BlocProvider<features_th.TradeHistoryBloc>(
          create:
              (_) =>
                  sl<features_th.TradeHistoryBloc>()
                    ..add(const features_th_events.LoadTradeHistory()),
        ),
      ],
      child: MaterialApp.router(
        title: 'NeoTradingBot 1777',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: sl<GoRouter>(),
      ),
    );
  }
}
