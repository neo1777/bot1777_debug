import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:path/path.dart' as p;

class EnvConfig {
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  bool _isLoaded = false;
  final _log = LogManager.getLogger();
  final DotEnv _dotEnv = DotEnv(includePlatformEnvironment: true);

  void ensureLoaded() {
    if (_isLoaded) return;

    // Try loading from multiple candidates
    final candidates = [
      '.env',
      'neotradingbotback1777/.env',
      p.join(Directory.current.path, '.env'),
      p.join(Directory.current.path, 'neotradingbotback1777', '.env'),
    ];

    bool found = false;
    for (final path in candidates) {
      if (File(path).existsSync()) {
        _dotEnv.load([path]);
        _log.i('Environment loaded from: $path');
        found = true;
        break;
      }
    }

    if (!found) {
      _log.w(
          'No .env file found in standard locations. Using system environment only.');
    }

    _isLoaded = true;
  }

  String? get(String key) {
    ensureLoaded();
    final envValue = _dotEnv[key];
    if (envValue != null && envValue.isNotEmpty) return envValue;
    return null;
  }

  int getInt(String key, int defaultValue) {
    final stringValue = get(key);
    if (stringValue == null) return defaultValue;
    return int.tryParse(stringValue) ?? defaultValue;
  }

  bool getBool(String key, bool defaultValue) {
    final boolValueStr = get(key)?.toLowerCase();
    if (boolValueStr == null) return defaultValue;
    return boolValueStr == 'true' ||
        boolValueStr == '1' ||
        boolValueStr == 'yes';
  }
}
