import 'package:flutter/material.dart';

/// Helper centralizzato per le notifiche SnackBar nell'applicazione.
///
/// Garantisce consistenza visiva, evita duplicati (clearSnackBars prima di ogni
/// nuova notifica) e centralizza la logica di styling.
///
/// Uso:
/// ```dart
/// AppSnackBar.showSuccess(context, 'Operazione completata');
/// AppSnackBar.showError(context, 'Errore di rete');
/// AppSnackBar.showWarning(context, 'Attenzione: dati non aggiornati');
/// AppSnackBar.showInfo(context, 'Connessione in corso...');
/// ```
class AppSnackBar {
  AppSnackBar._();

  /// Durata standard per i messaggi.
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Durata estesa per errori (più tempo per leggere).
  static const Duration _errorDuration = Duration(seconds: 5);

  /// Mostra una notifica di **successo** (verde).
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade700,
      duration: _defaultDuration,
    );
  }

  /// Mostra una notifica di **errore** (rosso).
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade700,
      duration: _errorDuration,
    );
  }

  /// Mostra una notifica di **warning** (arancione).
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.orange.shade700,
      duration: _defaultDuration,
    );
  }

  /// Mostra una notifica **informativa** (blu).
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: Colors.blueGrey.shade700,
      duration: _defaultDuration,
    );
  }

  /// Implementazione interna. Cancella le SnackBar precedenti prima di mostrarne
  /// una nuova per evitare accumulo.
  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: duration,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
