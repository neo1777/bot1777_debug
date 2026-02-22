import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/app.dart';
import 'package:neotradingbotfront1777/core/di/injection.dart';

Future<void> main() async {
  // Assicura che i binding di Flutter siano inizializzati prima di qualsiasi altra operazione.
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza il nostro service locator (GetIt) e tutte le dipendenze.
  await configureDependencies();

  //debugPrintRebuildDirtyWidgets = true; // Mostra widget rebuilds

  // Avvia l'applicazione.
  runApp(const MyApp());
}
