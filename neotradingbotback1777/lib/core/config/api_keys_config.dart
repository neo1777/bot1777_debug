import 'package:fpdart/fpdart.dart';
import 'package:neotradingbotback1777/core/config/env_config.dart';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/failures/failures.dart';

/// Configurazione separata per le credenziali Telegram.
/// Isolata da ApiKeysConfig per ridurre il blast radius in caso di compromissione.
class TelegramConfig {
  final String? botToken;
  final String? chatId;

  const TelegramConfig({this.botToken, this.chatId});

  bool get isConfigured => botToken != null && botToken!.isNotEmpty;

  /// Carica la configurazione Telegram dalle variabili d'ambiente.
  static TelegramConfig loadFromEnv() {
    final env = EnvConfig();
    final token = env.get('TELEGRAM_BOT_TOKEN');
    final chatId = env.get('TELEGRAM_CHAT_ID');

    if (token != null && token.isNotEmpty) {
      final log = LogManager.getLogger();
      log.i('[CONFIG] Telegram notifiche configurate.');
    }

    return TelegramConfig(botToken: token, chatId: chatId);
  }
}

/// Configurazione per le API keys di Binance (Real + Testnet).
/// NON contiene più le credenziali Telegram — usare [TelegramConfig] separatamente.
class ApiKeysConfig {
  final String apiKey;
  final String secretKey;
  final String testApiKey;
  final String testSecretKey;

  /// @deprecated Usare [TelegramConfig.botToken] direttamente.
  final String? telegramBotToken;

  /// @deprecated Usare [TelegramConfig.chatId] direttamente.
  final String? telegramChatId;

  ApiKeysConfig({
    required this.apiKey,
    required this.secretKey,
    required this.testApiKey,
    required this.testSecretKey,
    this.telegramBotToken,
    this.telegramChatId,
  });

  /// Valida una API key di Binance secondo i criteri di sicurezza.
  /// Le API key di Binance hanno una lunghezza fissa e contengono solo caratteri alfanumerici.
  static Either<ValidationFailure, String> _validateApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) {
      return Left(ValidationFailure(
        message: 'API_KEY non può essere vuota',
        code: 'EMPTY_API_KEY',
      ));
    }

    // Binance API keys hanno lunghezza fissa di 64 caratteri
    if (apiKey.length != 64) {
      return Left(ValidationFailure(
        message:
            'API_KEY deve essere esattamente di 64 caratteri (lunghezza attuale: ${apiKey.length})',
        code: 'INVALID_API_KEY_LENGTH',
        details: {'expectedLength': 64, 'actualLength': apiKey.length},
      ));
    }

    // Controlla che contenga solo caratteri alfanumerici (a-z, A-Z, 0-9)
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(apiKey)) {
      return Left(ValidationFailure(
        message:
            'API_KEY può contenere solo caratteri alfanumerici (a-z, A-Z, 0-9)',
        code: 'INVALID_API_KEY_CHARS',
        details: {
          'invalidChars': apiKey.replaceAll(RegExp(r'[a-zA-Z0-9]'), '')
        },
      ));
    }

    return Right(apiKey);
  }

  /// Valida una Secret key di Binance secondo i criteri di sicurezza.
  /// Le Secret key di Binance hanno una lunghezza fissa e contengono solo caratteri alfanumerici.
  static Either<ValidationFailure, String> _validateSecretKey(
      String? secretKey) {
    if (secretKey == null || secretKey.isEmpty) {
      return Left(ValidationFailure(
        message: 'SECRET_KEY non può essere vuota',
        code: 'EMPTY_SECRET_KEY',
      ));
    }

    // Binance Secret keys hanno lunghezza fissa di 64 caratteri
    if (secretKey.length != 64) {
      return Left(ValidationFailure(
        message:
            'SECRET_KEY deve essere esattamente di 64 caratteri (lunghezza attuale: ${secretKey.length})',
        code: 'INVALID_SECRET_KEY_LENGTH',
        details: {'expectedLength': 64, 'actualLength': secretKey.length},
      ));
    }

    // Controlla che contenga solo caratteri alfanumerici (a-z, A-Z, 0-9)
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(secretKey)) {
      return Left(ValidationFailure(
        message:
            'SECRET_KEY può contenere solo caratteri alfanumerici (a-z, A-Z, 0-9)',
        code: 'INVALID_SECRET_KEY_CHARS',
        details: {
          'invalidChars': secretKey.replaceAll(RegExp(r'[a-zA-Z0-9]'), '')
        },
      ));
    }

    return Right(secretKey);
  }

  /// Carica e valida le API keys dalle variabili d'ambiente.
  /// Restituisce un ValidationFailure se le chiavi non sono valide.
  static Either<ValidationFailure, ApiKeysConfig> loadFromEnv() {
    final env = EnvConfig();
    final apiKey = env.get('API_KEY');
    final secretKey = env.get('SECRET_KEY');
    final testApiKey = env.get('TEST_API_KEY') ?? '';
    final testSecretKey = env.get('TEST_SECRET_KEY') ?? '';

    // Valida API key reale
    final apiKeyValidation = _validateApiKey(apiKey);
    if (apiKeyValidation.isLeft()) {
      return Left(apiKeyValidation.fold(
          (f) => f, (_) => throw Exception('Unexpected error')));
    }

    // Valida Secret key reale
    final secretKeyValidation = _validateSecretKey(secretKey);
    if (secretKeyValidation.isLeft()) {
      return Left(secretKeyValidation.fold(
          (f) => f, (_) => throw Exception('Unexpected error')));
    }

    // Nota: Le chiavi di test potrebbero essere opzionali o non presenti all'avvio.
    // Se presenti, le validiamo. Altrimenti lasciamo stringa vuota.
    if (testApiKey.isNotEmpty) {
      final v = _validateApiKey(testApiKey);
      if (v.isLeft()) {
        return Left(
            v.fold((f) => f, (_) => throw Exception('Unexpected error')));
      }
    }

    if (testSecretKey.isNotEmpty) {
      final v = _validateSecretKey(testSecretKey);
      if (v.isLeft()) {
        return Left(
            v.fold((f) => f, (_) => throw Exception('Unexpected error')));
      }
    }

    // Se tutte le validazioni (per le chiavi presenti) sono passate, crea la configurazione
    return Right(ApiKeysConfig(
      apiKey: apiKeyValidation.fold(
          (f) => throw Exception('Unexpected error'), (k) => k),
      secretKey: secretKeyValidation.fold(
          (f) => throw Exception('Unexpected error'), (k) => k),
      testApiKey: testApiKey,
      testSecretKey: testSecretKey,
      telegramBotToken: env.get('TELEGRAM_BOT_TOKEN'),
      telegramChatId: env.get('TELEGRAM_CHAT_ID'),
    ));
  }

  /// Restituisce la coppia di chiavi appropriata per la modalità corrente.
  (String, String) getKeysForMode({required bool isTestMode}) {
    if (isTestMode) {
      return (testApiKey, testSecretKey);
    }
    return (apiKey, secretKey);
  }

  /// Metodo legacy per compatibilità con il codice esistente.
  /// DEPRECATO: utilizzare loadFromEnv() che restituisce Either\<ValidationFailure, ApiKeysConfig>
  @Deprecated(
      'Utilizzare loadFromEnv() che restituisce Either<ValidationFailure, ApiKeysConfig>')
  static ApiKeysConfig loadFromEnvLegacy() {
    final result = loadFromEnv();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (config) => config,
    );
  }
}
