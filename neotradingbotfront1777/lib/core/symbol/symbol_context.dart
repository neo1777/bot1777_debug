import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestore centralizzato del simbolo corrente e, in prospettiva, del portafoglio di strategie.
/// - Ora: mantiene un singolo `activeSymbol` con persistenza locale.
/// - Futuro: potrà gestire una lista di simboli attivi e relativi stati per multi-strategia.
class SymbolContext extends ChangeNotifier {
  static const String _prefsKeyActiveSymbol = 'active_symbol';

  late SharedPreferences _prefs;
  String _activeSymbol = '';

  String get activeSymbol => _activeSymbol;

  Future<void> initialize({required String defaultSymbol}) async {
    _prefs = await SharedPreferences.getInstance();
    _activeSymbol = _prefs.getString(_prefsKeyActiveSymbol) ?? defaultSymbol;
  }

  Future<void> setActiveSymbol(String symbol) async {
    if (symbol == _activeSymbol) return;
    _activeSymbol = symbol;
    await _prefs.setString(_prefsKeyActiveSymbol, symbol);
    notifyListeners();
  }
}
