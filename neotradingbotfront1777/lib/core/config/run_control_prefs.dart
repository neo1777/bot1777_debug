import 'package:shared_preferences/shared_preferences.dart';

/// Preferenze locali per controllare l'esecuzione della strategia lato client.
/// - stopAfterNextSell: se true, alla prossima chiusura di round viene inviato STOP.
/// - maxCycles: numero massimo di round da eseguire (0 = infinito) per simbolo.
class RunControlPrefs {
  static const String _keyStopAfterNextSellPrefix = 'rc_stop_after_next_sell_';
  static const String _keyMaxCyclesPrefix = 'rc_max_cycles_';
  static const String _keyBaseRoundIdPrefix = 'rc_base_round_id_';

  static Future<bool> getStopAfterNextSell(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyStopAfterNextSellPrefix$symbol') ?? false;
  }

  static Future<void> setStopAfterNextSell(String symbol, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyStopAfterNextSellPrefix$symbol', value);
  }

  static Future<int> getMaxCycles(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyMaxCyclesPrefix$symbol') ?? 0; // 0 = infinito
  }

  static Future<void> setMaxCycles(String symbol, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyMaxCyclesPrefix$symbol', value);
  }

  static Future<int?> getBaseRoundId(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyBaseRoundIdPrefix$symbol');
  }

  static Future<void> setBaseRoundId(String symbol, int roundId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyBaseRoundIdPrefix$symbol', roundId);
  }

  static Future<void> clearForSymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyStopAfterNextSellPrefix$symbol');
    await prefs.remove('$_keyMaxCyclesPrefix$symbol');
    await prefs.remove('$_keyBaseRoundIdPrefix$symbol');
  }
}
