import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neotradingbotfront1777/core/error/error_handler.dart';
import 'package:neotradingbotfront1777/core/theme/app_theme.dart';

/// Error display widget with Solo Leveling theme
class ErrorDisplayWidget extends StatelessWidget {
  const ErrorDisplayWidget({
    required this.error,
    super.key,
    this.onRetry,
    this.onDismiss,
    this.showDetails = false,
  });

  final UserError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: error.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: error.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: error.color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: error.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(error.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSeverityLabel(error.severity),
                      style: TextStyle(
                        color: error.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      error.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  color: AppTheme.mutedTextColor,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                _formatTimestamp(error.timestamp),
                style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
              ),
              const Spacer(),
              if (error.canRetry && onRetry != null) ...[
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Riprova'),
                  style: TextButton.styleFrom(foregroundColor: error.color),
                ),
                const SizedBox(width: 8),
              ],
              if (showDetails)
                TextButton.icon(
                  onPressed: () => _showErrorDetails(context),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Dettagli'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.mutedTextColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSeverityLabel(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.low:
        return 'ATTENZIONE';
      case ErrorSeverity.medium:
        return 'ERRORE';
      case ErrorSeverity.high:
        return 'ERRORE GRAVE';
      case ErrorSeverity.critical:
        return 'ERRORE CRITICO';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Ora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m fa';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h fa';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(error.icon, color: error.color),
                const SizedBox(width: 8),
                const Text('Dettagli Errore'),
              ],
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Severità', _getSeverityLabel(error.severity)),
                _buildDetailRow('Messaggio', error.message),
                _buildDetailRow('Timestamp', error.timestamp.toString()),
                _buildDetailRow('Può riprovare', error.canRetry ? 'Sì' : 'No'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Chiudi'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedTextColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error snackbar with themed styling
class ErrorSnackBar {
  static void show(
    BuildContext context,
    UserError error, {
    VoidCallback? onRetry,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error.color,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            Icon(error.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action:
            error.canRetry && onRetry != null
                ? SnackBarAction(
                  label: 'RIPROVA',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
                : null,
      ),
    );
  }
}

/// Error boundary for specific widgets
class WidgetErrorBoundary extends StatefulWidget {
  const WidgetErrorBoundary({
    required this.child,
    super.key,
    this.fallback,
    this.onError,
  });

  final Widget child;
  final Widget? fallback;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  State<WidgetErrorBoundary> createState() => _WidgetErrorBoundaryState();
}

class _WidgetErrorBoundaryState extends State<WidgetErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback ?? _buildDefaultErrorWidget();
    }

    return ErrorCatcher(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
        });

        widget.onError?.call(error, stackTrace);

        ErrorHandler().handleError(
          error,
          stackTrace: stackTrace,
          context: 'WidgetErrorBoundary',
          severity: ErrorSeverity.medium,
          showToUser: false,
        );
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
          const SizedBox(height: 8),
          Text(
            'Errore Widget',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Si è verificato un errore in questo componente',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}

/// Error catcher widget
class ErrorCatcher extends StatefulWidget {
  const ErrorCatcher({required this.child, required this.onError, super.key});

  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  @override
  State<ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    try {
      return widget.child;
    } catch (error, stackTrace) {
      widget.onError(error, stackTrace);
      rethrow;
    }
  }
}

/// Error listener widget that shows errors from ErrorHandler
class ErrorListenerWidget extends StatefulWidget {
  const ErrorListenerWidget({
    required this.child,
    super.key,
    this.showSnackbars = true,
    this.autoHideAfter = const Duration(seconds: 5),
  });

  final Widget child;
  final bool showSnackbars;
  final Duration autoHideAfter;

  @override
  State<ErrorListenerWidget> createState() => _ErrorListenerWidgetState();
}

class _ErrorListenerWidgetState extends State<ErrorListenerWidget>
    implements ErrorListener {
  final ErrorHandler _errorHandler = ErrorHandler();
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _errorHandler.addListener(this);

    // Periodically check for user errors
    _checkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkForUserErrors();
    });
  }

  @override
  void dispose() {
    _errorHandler.removeListener(this);
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  Future<void> onError(AppError error) async {
    // This will be called by ErrorHandler when errors occur
  }

  void _checkForUserErrors() {
    final userError = _errorHandler.lastUserError;
    if (userError != null && widget.showSnackbars && mounted) {
      _errorHandler.clearLastUserError();

      ErrorSnackBar.show(context, userError, duration: widget.autoHideAfter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Network error widget for connection issues
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Nessuna connessione internet',
  });

  final VoidCallback? onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wifi_off, size: 48, color: AppTheme.errorColor),
          ),
          const SizedBox(height: 20),
          Text(
            'Connessione Persa',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedTextColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (onRetry != null)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Riconnetti'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
