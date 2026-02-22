import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';

/// Comprehensive error handling system for the trading bot
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<ErrorListener> _listeners = [];
  final List<AppError> _errorHistory = [];

  /// Register error listener
  void addListener(ErrorListener listener) {
    _listeners.add(listener);
  }

  /// Remove error listener
  void removeListener(ErrorListener listener) {
    _listeners.remove(listener);
  }

  /// Handle error with comprehensive logging and user notification
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    bool showToUser = true,
    Map<String, dynamic>? metadata,
  }) async {
    final appError = _createAppError(
      error,
      stackTrace: stackTrace,
      context: context,
      severity: severity,
      metadata: metadata,
    );

    // Add to history
    _errorHistory.add(appError);
    if (_errorHistory.length > 100) {
      _errorHistory.removeAt(0);
    }

    // Log error
    _logError(appError);

    // Notify listeners
    for (final listener in _listeners) {
      try {
        await listener.onError(appError);
      } catch (e) {
        developer.log(
          'Error in error listener: $e',
          name: 'ErrorHandler',
          level: 1000,
        );
      }
    }

    // Show to user if requested
    if (showToUser) {
      _showErrorToUser(appError);
    }
  }

  /// Handle gRPC specific errors
  Future<void> handleGrpcError(
    GrpcError error, {
    String? context,
    bool showToUser = true,
  }) async {
    final severity = _getGrpcErrorSeverity(error);
    final userMessage = _getGrpcUserMessage(error);

    await handleError(
      error,
      context: context,
      severity: severity,
      showToUser: showToUser,
      metadata: {
        'grpcCode': error.code,
        'grpcMessage': error.message,
        'isGrpcError': true,
        'userMessage': userMessage,
      },
    );
  }

  /// Handle network connectivity errors
  Future<void> handleNetworkError(
    dynamic error, {
    String? context,
    bool showToUser = true,
  }) async {
    await handleError(
      error,
      context: context,
      severity: ErrorSeverity.high,
      showToUser: showToUser,
      metadata: {
        'isNetworkError': true,
        'userMessage':
            'Errore di connessione. Controlla la tua connessione internet.',
      },
    );
  }

  /// Get error history
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  /// Clear error history
  void clearHistory() {
    _errorHistory.clear();
  }

  /// Get error statistics
  ErrorStats get stats {
    final now = DateTime.now();
    final last24h =
        _errorHistory
            .where((e) => now.difference(e.timestamp).inHours < 24)
            .length;
    final lastHour =
        _errorHistory
            .where((e) => now.difference(e.timestamp).inMinutes < 60)
            .length;

    final severityCounts = <ErrorSeverity, int>{};
    for (final error in _errorHistory) {
      severityCounts[error.severity] =
          (severityCounts[error.severity] ?? 0) + 1;
    }

    return ErrorStats(
      totalErrors: _errorHistory.length,
      errorsLast24h: last24h,
      errorsLastHour: lastHour,
      severityCounts: severityCounts,
      mostCommonError: _getMostCommonError(),
    );
  }

  AppError _createAppError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    Map<String, dynamic>? metadata,
  }) {
    return AppError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: error.toString(),
      originalError: error,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context,
      severity: severity,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
  }

  void _logError(AppError error) {
    final level =
        error.severity == ErrorSeverity.low
            ? 800
            : error.severity == ErrorSeverity.medium
            ? 900
            : 1000;

    developer.log(
      '${error.severity.name.toUpperCase()}: ${error.message}',
      name: 'ErrorHandler',
      level: level,
      error: error.originalError,
      stackTrace: error.stackTrace,
      time: error.timestamp,
    );

    if (kDebugMode) {
      debugPrint('🔥 Error [${error.severity.name}]: ${error.message}');
      if (error.context != null) {
        debugPrint('   Context: ${error.context}');
      }
      if (error.metadata.isNotEmpty) {
        debugPrint('   Metadata: ${error.metadata}');
      }
    }
  }

  void _showErrorToUser(AppError error) {
    final message =
        error.metadata['userMessage'] as String? ??
        _getDefaultUserMessage(error);

    // This would be called through a global navigator or overlay
    // For now, we'll just store it for UI components to pick up
    _lastUserError = UserError(
      message: message,
      severity: error.severity,
      timestamp: error.timestamp,
      canRetry: _canRetry(error),
    );
  }

  UserError? _lastUserError;
  UserError? get lastUserError => _lastUserError;
  void clearLastUserError() => _lastUserError = null;

  String _getDefaultUserMessage(AppError error) {
    if (error.originalError is GrpcError) {
      return _getGrpcUserMessage(error.originalError as GrpcError);
    }

    switch (error.severity) {
      case ErrorSeverity.low:
        return 'Si è verificato un problema minore';
      case ErrorSeverity.medium:
        return 'Si è verificato un errore';
      case ErrorSeverity.high:
        return 'Si è verificato un errore grave';
      case ErrorSeverity.critical:
        return 'Errore critico del sistema';
    }
  }

  ErrorSeverity _getGrpcErrorSeverity(GrpcError error) {
    switch (error.code) {
      case StatusCode.unavailable:
      case StatusCode.deadlineExceeded:
        return ErrorSeverity.high;
      case StatusCode.unauthenticated:
      case StatusCode.permissionDenied:
        return ErrorSeverity.critical;
      case StatusCode.notFound:
      case StatusCode.alreadyExists:
        return ErrorSeverity.medium;
      default:
        return ErrorSeverity.medium;
    }
  }

  String _getGrpcUserMessage(GrpcError error) {
    switch (error.code) {
      case StatusCode.unavailable:
        return 'Il servizio non è disponibile al momento';
      case StatusCode.deadlineExceeded:
        return 'Operazione scaduta. Riprova più tardi';
      case StatusCode.unauthenticated:
        return 'Errore di autenticazione';
      case StatusCode.permissionDenied:
        return 'Accesso negato';
      case StatusCode.notFound:
        return 'Risorsa non trovata';
      case StatusCode.alreadyExists:
        return 'Risorsa già esistente';
      case StatusCode.invalidArgument:
        return 'Parametri non validi';
      default:
        return error.message ?? 'Errore del server';
    }
  }

  bool _canRetry(AppError error) {
    if (error.originalError is GrpcError) {
      final grpcError = error.originalError as GrpcError;
      return grpcError.code == StatusCode.unavailable ||
          grpcError.code == StatusCode.deadlineExceeded;
    }
    return true;
  }

  String? _getMostCommonError() {
    if (_errorHistory.isEmpty) return null;

    final errorCounts = <String, int>{};
    for (final error in _errorHistory) {
      final key = error.originalError.runtimeType.toString();
      errorCounts[key] = (errorCounts[key] ?? 0) + 1;
    }

    return errorCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Error listener interface
abstract class ErrorListener {
  Future<void> onError(AppError error);
}

/// Comprehensive error information
class AppError {
  final String id;
  final String message;
  final dynamic originalError;
  final StackTrace stackTrace;
  final String? context;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const AppError({
    required this.id,
    required this.message,
    required this.originalError,
    required this.stackTrace,
    required this.severity,
    required this.timestamp,
    this.context,
    this.metadata = const {},
  });

  @override
  String toString() {
    return 'AppError(id: $id, message: $message, severity: $severity, context: $context)';
  }
}

/// Error severity levels
enum ErrorSeverity {
  low, // Info/warning level
  medium, // Standard errors
  high, // Service disruption
  critical, // System failure
}

/// User-facing error information
class UserError {
  final String message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final bool canRetry;

  const UserError({
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.canRetry,
  });

  Color get color {
    switch (severity) {
      case ErrorSeverity.low:
        return Colors.amber;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData get icon {
    switch (severity) {
      case ErrorSeverity.low:
        return Icons.info;
      case ErrorSeverity.medium:
        return Icons.warning;
      case ErrorSeverity.high:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }
}

/// Error statistics
class ErrorStats {
  final int totalErrors;
  final int errorsLast24h;
  final int errorsLastHour;
  final Map<ErrorSeverity, int> severityCounts;
  final String? mostCommonError;

  const ErrorStats({
    required this.totalErrors,
    required this.errorsLast24h,
    required this.errorsLastHour,
    required this.severityCounts,
    this.mostCommonError,
  });

  @override
  String toString() {
    return 'ErrorStats(total: $totalErrors, 24h: $errorsLast24h, 1h: $errorsLastHour)';
  }
}

/// Error handling mixin for BLoCs and other classes
mixin ErrorHandlingMixin {
  final ErrorHandler _errorHandler = ErrorHandler();

  /// Handle error with context
  Future<void> handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    ErrorSeverity severity = ErrorSeverity.medium,
    bool showToUser = true,
  }) async {
    await _errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: context ?? runtimeType.toString(),
      severity: severity,
      showToUser: showToUser,
    );
  }

  /// Handle gRPC error
  Future<void> handleGrpcError(GrpcError error, {String? context}) async {
    await _errorHandler.handleGrpcError(
      error,
      context: context ?? runtimeType.toString(),
    );
  }

  /// Handle network error
  Future<void> handleNetworkError(dynamic error, {String? context}) async {
    await _errorHandler.handleNetworkError(
      error,
      context: context ?? runtimeType.toString(),
    );
  }
}

/// Global error boundary widget
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    super.key,
    this.onError,
    this.fallbackBuilder,
  });

  final Widget child;
  final void Function(FlutterErrorDetails)? onError;
  final Widget Function(FlutterErrorDetails)? fallbackBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  FlutterExceptionHandler? _previousOnError;

  @override
  void initState() {
    super.initState();

    // Chain con il precedente handler invece di sovrascriverlo
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Esegui il handler precedente (Crashlytics, logging, etc.)
      _previousOnError?.call(details);

      ErrorHandler().handleError(
        details.exception,
        stackTrace: details.stack,
        context: 'FlutterError',
        severity: ErrorSeverity.high,
      );

      widget.onError?.call(details);

      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
    };
  }

  @override
  void dispose() {
    // Ripristina il handler precedente per pulizia
    FlutterError.onError = _previousOnError;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.fallbackBuilder?.call(_errorDetails!) ??
          _buildDefaultErrorWidget(_errorDetails!);
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade600),
                const SizedBox(height: 16),
                Text(
                  'Si è verificato un errore',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'L\'applicazione ha riscontrato un problema imprevisto.',
                  style: TextStyle(fontSize: 16, color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorDetails = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                  ),
                  child: const Text(
                    'Riprova',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('Dettagli Errore (Debug)'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          details.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
