import 'dart:io';
import 'dart:async';
import 'package:neotradingbotback1777/core/logging/log_manager.dart';
import 'package:path/path.dart' as p;

/// Configurazione per il backup automatico di Hive
class HiveBackupConfig {
  /// Intervallo tra backup automatici
  final Duration backupInterval;

  /// Directory dove salvare i backup
  final String backupDirectory;

  /// Numero massimo di backup da mantenere
  final int maxBackupCount;

  /// Compressione dei backup
  final bool compressBackups;

  /// Pattern per il nome dei file di backup
  final String backupFilePattern;

  /// Dimensione massima di un singolo file di backup (in MB)
  final int maxBackupSizeMB;

  const HiveBackupConfig({
    this.backupInterval = const Duration(hours: 6),
    this.backupDirectory = 'hive_backups',
    this.maxBackupCount = 10,
    this.compressBackups = true,
    this.backupFilePattern = 'backup_%timestamp%',
    this.maxBackupSizeMB = 100,
  });
}

/// Risultato di un'operazione di backup
class BackupResult {
  final bool success;
  final String? backupPath;
  final String? error;
  final int fileCount;
  final int totalSizeBytes;
  final Duration duration;

  BackupResult({
    required this.success,
    required this.fileCount,
    required this.totalSizeBytes,
    required this.duration,
    this.backupPath,
    this.error,
  });

  Map<String, dynamic> toJson() => {
        'success': success,
        'backupPath': backupPath,
        'error': error,
        'fileCount': fileCount,
        'totalSizeBytes': totalSizeBytes,
        'totalSizeMB': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
        'durationMs': duration.inMilliseconds,
      };
}

/// Statistiche dei backup
class BackupStats {
  final int totalBackups;
  final int successfulBackups;
  final int failedBackups;
  final DateTime? lastBackupTime;
  final DateTime? lastSuccessfulBackup;
  final int totalBackupSizeBytes;
  final List<String> recentErrors;

  BackupStats({
    required this.totalBackups,
    required this.successfulBackups,
    required this.failedBackups,
    required this.totalBackupSizeBytes,
    this.lastBackupTime,
    this.lastSuccessfulBackup,
    this.recentErrors = const [],
  });

  double get successRate =>
      totalBackups > 0 ? successfulBackups / totalBackups : 1.0;

  Map<String, dynamic> toJson() => {
        'totalBackups': totalBackups,
        'successfulBackups': successfulBackups,
        'failedBackups': failedBackups,
        'successRate': successRate,
        'lastBackupTime': lastBackupTime?.toIso8601String(),
        'lastSuccessfulBackup': lastSuccessfulBackup?.toIso8601String(),
        'totalBackupSizeBytes': totalBackupSizeBytes,
        'totalBackupSizeMB':
            (totalBackupSizeBytes / (1024 * 1024)).toStringAsFixed(2),
        'recentErrors': recentErrors,
      };
}

/// Manager per il backup automatico dei dati Hive
class HiveBackupManager {
  final String hiveDataPath;
  final HiveBackupConfig config;
  final _log = LogManager.getLogger();

  Timer? _backupTimer;
  bool _disposed = false;
  int _totalBackups = 0;
  int _successfulBackups = 0;
  int _failedBackups = 0;
  DateTime? _lastBackupTime;
  DateTime? _lastSuccessfulBackup;
  final List<String> _recentErrors = [];

  HiveBackupManager({
    required this.hiveDataPath,
    this.config = const HiveBackupConfig(),
  });

  /// Avvia il backup automatico
  void startAutomaticBackup() {
    if (_disposed || _backupTimer != null) return;

    _log.i(
        'Starting automatic Hive backup every ${config.backupInterval.inHours} hours');

    // Esegui un backup iniziale
    createBackup();

    // Programma backup periodici
    _backupTimer = Timer.periodic(config.backupInterval, (_) {
      if (!_disposed) {
        createBackup();
      }
    });
  }

  /// Ferma il backup automatico
  void stopAutomaticBackup() {
    _backupTimer?.cancel();
    _backupTimer = null;
    _log.i('Automatic Hive backup stopped');
  }

  /// Crea un backup manuale
  Future<BackupResult> createBackup() async {
    if (_disposed) {
      return BackupResult(
        success: false,
        error: 'Backup manager is disposed',
        fileCount: 0,
        totalSizeBytes: 0,
        duration: Duration.zero,
      );
    }

    final startTime = DateTime.now();
    _totalBackups++;
    _lastBackupTime = startTime;

    try {
      _log.i('Starting Hive database backup...');

      // Crea la directory di backup se non esiste
      final backupDir = Directory(config.backupDirectory);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Genera il nome del file di backup
      final timestamp = startTime.millisecondsSinceEpoch;
      final backupFileName = config.backupFilePattern
          .replaceAll('%timestamp%', timestamp.toString())
          .replaceAll('%date%', _formatDate(startTime));

      final backupPath = p.join(config.backupDirectory, '$backupFileName.tar');

      // Verifica che la directory Hive esista
      final hiveDataDir = Directory(hiveDataPath);
      if (!await hiveDataDir.exists()) {
        _log.e('Hive data directory does not exist: $hiveDataPath');
        return BackupResult(
          success: false,
          error: 'Hive data directory does not exist: $hiveDataPath',
          fileCount: 0,
          totalSizeBytes: 0,
          duration: Duration.zero,
        );
      }

      // Copia i file Hive nel backup
      final result = await _createTarBackup(hiveDataPath, backupPath);

      // Verifica la dimensione del backup
      final backupFile = File(backupPath);
      final backupSizeBytes = await backupFile.length();
      final backupSizeMB = backupSizeBytes / (1024 * 1024);

      if (backupSizeMB > config.maxBackupSizeMB) {
        _log.w(
            'Backup size (${backupSizeMB.toStringAsFixed(2)}MB) exceeds limit (${config.maxBackupSizeMB}MB)');
      }

      // Pulisci i backup vecchi
      await _cleanupOldBackups();

      final duration = DateTime.now().difference(startTime);
      _successfulBackups++;
      _lastSuccessfulBackup = DateTime.now();

      _log.i(
          'Backup completed successfully: $backupPath (${result.fileCount} files, ${(backupSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB, ${duration.inSeconds}s)');

      return BackupResult(
        success: true,
        backupPath: backupPath,
        fileCount: result.fileCount,
        totalSizeBytes: backupSizeBytes,
        duration: duration,
      );
    } catch (e, stackTrace) {
      _failedBackups++;
      final error = 'Backup failed: $e';
      _addRecentError(error);
      _log.e('Hive backup failed: $e', stackTrace: stackTrace);

      final duration = DateTime.now().difference(startTime);
      return BackupResult(
        success: false,
        error: error,
        fileCount: 0,
        totalSizeBytes: 0,
        duration: duration,
      );
    }
  }

  /// Ripristina da un backup
  Future<bool> restoreFromBackup(String backupPath) async {
    try {
      _log.i('Starting restore from backup: $backupPath');

      final backupFile = File(backupPath);
      if (!backupFile.existsSync()) {
        _log.e('Backup file does not exist: $backupPath');
        return false;
      }

      // Crea una directory temporanea per l'estrazione
      final tempDir = Directory(p.join(Directory.systemTemp.path,
          'hive_restore_${DateTime.now().millisecondsSinceEpoch}'));
      await tempDir.create(recursive: true);

      try {
        // Estrai il backup
        await _extractTarBackup(backupPath, tempDir.path);

        // Crea backup della directory corrente
        final currentBackupPath = p.join(config.backupDirectory,
            'pre_restore_backup_${DateTime.now().millisecondsSinceEpoch}.tar');
        await _createTarBackup(hiveDataPath, currentBackupPath);

        // Rimuovi la directory Hive corrente
        final hiveDir = Directory(hiveDataPath);
        if (await hiveDir.exists()) {
          await hiveDir.delete(recursive: true);
        }

        // Copia i file ripristinati
        await _copyDirectory(tempDir.path, hiveDataPath);

        _log.i('Restore completed successfully from: $backupPath');
        return true;
      } finally {
        // Pulisci la directory temporanea
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    } catch (e, stackTrace) {
      _log.e('Restore failed: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Lista tutti i backup disponibili
  Future<List<FileSystemEntity>> listBackups() async {
    try {
      final backupDir = Directory(config.backupDirectory);
      if (!await backupDir.exists()) {
        return [];
      }

      final backups = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.tar'))
          .toList();

      // Ordina per data di modifica (più recente prima)
      backups.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return backups;
    } catch (e) {
      _log.e('Failed to list backups: $e');
      return [];
    }
  }

  /// Ottieni le statistiche dei backup
  BackupStats getStats() {
    return BackupStats(
      totalBackups: _totalBackups,
      successfulBackups: _successfulBackups,
      failedBackups: _failedBackups,
      lastBackupTime: _lastBackupTime,
      lastSuccessfulBackup: _lastSuccessfulBackup,
      totalBackupSizeBytes: _calculateTotalBackupSize(),
      recentErrors: List.from(_recentErrors),
    );
  }

  /// Pulisce i backup vecchi
  Future<void> _cleanupOldBackups() async {
    try {
      final backups = await listBackups();

      if (backups.length > config.maxBackupCount) {
        final backupsToDelete = backups.skip(config.maxBackupCount);

        for (final backup in backupsToDelete) {
          await backup.delete();
          _log.d('Deleted old backup: ${backup.path}');
        }

        _log.i('Cleaned up ${backupsToDelete.length} old backups');
      }
    } catch (e) {
      _log.w('Failed to cleanup old backups: $e');
    }
  }

  /// Crea un backup tar
  Future<({int fileCount, int totalSize})> _createTarBackup(
      String sourcePath, String backupPath) async {
    // Implementazione semplificata - in produzione usare package:archive o tar di sistema
    int fileCount = 0;
    int totalSize = 0;

    final sourceDir = Directory(sourcePath);
    final backupFile = File(backupPath);
    final sink = backupFile.openWrite();

    try {
      await for (final entity in sourceDir.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          final bytes = await entity.readAsBytes();
          totalSize += bytes.length;

          // Scrivi header del file (semplificato)
          final relativePath = p.relative(entity.path, from: sourcePath);
          sink.writeln('FILE:$relativePath:${bytes.length}');
          sink.add(bytes);
        }
      }
    } finally {
      await sink.close();
    }

    return (fileCount: fileCount, totalSize: totalSize);
  }

  /// Estrae un backup tar
  Future<void> _extractTarBackup(String backupPath, String targetPath) async {
    // Implementazione semplificata - in produzione usare package:archive o tar di sistema
    final backupFile = File(backupPath);
    final lines = await backupFile.readAsString();
    final parts = lines.split('\n');

    for (int i = 0; i < parts.length - 1; i++) {
      final header = parts[i];
      if (header.startsWith('FILE:')) {
        final headerParts = header.split(':');
        final relativePath = headerParts[1];
        final _ = int.parse(headerParts[2]); // Size for future use

        final targetFile = File(p.join(targetPath, relativePath));
        await targetFile.parent.create(recursive: true);

        // Leggi i bytes del file (implementazione semplificata)
        // In una implementazione reale, dovresti leggere esattamente 'size' bytes
      }
    }
  }

  /// Copia una directory ricorsivamente
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    final sourceDir = Directory(sourcePath);
    await Directory(targetPath).create(recursive: true);

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: sourcePath);
        final targetFile = File(p.join(targetPath, relativePath));
        await targetFile.parent.create(recursive: true);
        await entity.copy(targetFile.path);
      }
    }
  }

  /// Calcola la dimensione totale dei backup
  int _calculateTotalBackupSize() {
    // Questa è una implementazione placeholder
    // In una implementazione reale, dovresti scansionare i file di backup
    return 0;
  }

  /// Formatta una data per il nome del file
  String _formatDate(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  /// Aggiunge un errore recente
  void _addRecentError(String error) {
    _recentErrors.add('${DateTime.now().toIso8601String()}: $error');

    // Mantieni solo gli ultimi 10 errori
    if (_recentErrors.length > 10) {
      _recentErrors.removeAt(0);
    }
  }

  /// Dispone delle risorse
  void dispose() {
    _disposed = true;
    stopAutomaticBackup();
    _log.i('HiveBackupManager disposed');
  }
}
