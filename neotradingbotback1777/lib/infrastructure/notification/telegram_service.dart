import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:neotradingbotback1777/domain/services/i_notification_service.dart';

class TelegramService implements INotificationService {
  final String? botToken;
  final String? chatId;
  final http.Client httpClient;
  final _log = LogManager.getLogger();

  TelegramService({
    required this.botToken,
    required this.chatId,
    required this.httpClient,
  });

  @override
  Future<void> sendMessage(String message) async {
    if (botToken == null ||
        chatId == null ||
        botToken!.isEmpty ||
        chatId!.isEmpty) {
      _log.w(
          'Telegram Bot Token o Chat ID non configurati. Messaggio non inviato.');
      return;
    }

    try {
      final url = 'https://api.telegram.org/bot$botToken/sendMessage';
      final response = await httpClient.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'Markdown',
        }),
      );

      if (response.statusCode != 200) {
        _log.e(
            'Errore nell\'invio del messaggio Telegram: ${response.statusCode} - ${response.body}');
      } else {
        _log.i('Messaggio Telegram inviato con successo.');
      }
    } catch (e) {
      _log.e('Errore durante la chiamata API di Telegram: $e');
    }
  }
}
