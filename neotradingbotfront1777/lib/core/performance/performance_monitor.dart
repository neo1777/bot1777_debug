import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Comprehensive performance monitoring system
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, _PerformanceMetric> _metrics = {};
  final List<FrameMetric> _frameMetrics = [];
  final List<_MemoryMetric> _memoryMetrics = [];

  Timer? _memoryTimer;
  bool _isMonitoring = false;

  /// Start comprehensive performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;

    // Monitor frame performance
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrame);

    // Monitor memory usage every 5 seconds
    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _recordMemoryUsage();
    });

    developer.log('Performance monitoring started', name: 'PerformanceMonitor');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _memoryTimer?.cancel();

    developer.log('Performance monitoring stopped', name: 'PerformanceMonitor');
  }

  /// Start timing an operation
  void startTiming(String operationName) {
    _metrics[operationName] = _PerformanceMetric(
      name: operationName,
      stopwatch: Stopwatch()..start(),
    );
  }

  /// End timing and record
  void endTiming(String operationName, {int warnThresholdMs = 16}) {
    final metric = _metrics.remove(operationName);
    if (metric == null) return;

    metric.stopwatch.stop();
    final duration = metric.stopwatch.elapsed;
    metric.duration = duration;

    if (duration.inMilliseconds > warnThresholdMs && kDebugMode) {
      developer.log(
        'Slow operation: $operationName took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
        level: 900,
      );
    }
  }

  /// Time a future operation
  static Future<T> timeAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    int warnThresholdMs = 100,
  }) async {
    final monitor = PerformanceMonitor();
    monitor.startTiming(operationName);

    try {
      final result = await operation();
      monitor.endTiming(operationName, warnThresholdMs: warnThresholdMs);
      return result;
    } catch (e) {
      monitor.endTiming(operationName, warnThresholdMs: warnThresholdMs);
      rethrow;
    }
  }

  /// Time a synchronous operation
  static T timeSync<T>(
    String operationName,
    T Function() operation, {
    int warnThresholdMs = 16,
  }) {
    final monitor = PerformanceMonitor();
    monitor.startTiming(operationName);

    try {
      final result = operation();
      monitor.endTiming(operationName, warnThresholdMs: warnThresholdMs);
      return result;
    } catch (e) {
      monitor.endTiming(operationName, warnThresholdMs: warnThresholdMs);
      rethrow;
    }
  }

  /// Get performance statistics
  PerformanceStats get stats {
    final now = DateTime.now();

    // Calculate frame metrics for last minute
    final recentFrames =
        _frameMetrics
            .where((f) => now.difference(f.timestamp).inMinutes < 1)
            .toList();

    double avgFrameTime = 0;
    int jankFrames = 0;

    if (recentFrames.isNotEmpty) {
      avgFrameTime =
          recentFrames
              .map((f) => f.duration.inMicroseconds)
              .reduce((a, b) => a + b) /
          recentFrames.length /
          1000;

      jankFrames =
          recentFrames.where((f) => f.duration.inMilliseconds > 16).length;
    }

    // Calculate memory usage
    final recentMemory =
        _memoryMetrics
            .where((m) => now.difference(m.timestamp).inMinutes < 5)
            .toList();

    int avgMemoryUsage = 0;
    if (recentMemory.isNotEmpty) {
      avgMemoryUsage =
          recentMemory.map((m) => m.usageBytes).reduce((a, b) => a + b) ~/
          recentMemory.length;
    }

    return PerformanceStats(
      averageFrameTimeMs: avgFrameTime,
      jankFramesPerMinute: jankFrames,
      averageMemoryUsageMB: avgMemoryUsage / (1024 * 1024),
      totalFrames: recentFrames.length,
      isMonitoring: _isMonitoring,
    );
  }

  /// Get detailed frame metrics
  List<FrameMetric> getFrameMetrics({Duration? since}) {
    if (since == null) return List.from(_frameMetrics);

    final cutoff = DateTime.now().subtract(since);
    return _frameMetrics.where((f) => f.timestamp.isAfter(cutoff)).toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _frameMetrics.clear();
    _memoryMetrics.clear();
    _metrics.clear();
  }

  void _onFrame(Duration timestamp) {
    final now = DateTime.now();

    // Record frame timing
    if (_frameMetrics.isNotEmpty) {
      final lastFrame = _frameMetrics.last;
      final frameDuration = now.difference(lastFrame.timestamp);

      _frameMetrics.add(FrameMetric(timestamp: now, duration: frameDuration));
    } else {
      _frameMetrics.add(
        FrameMetric(
          timestamp: now,
          duration: const Duration(milliseconds: 16), // Assume 60fps baseline
        ),
      );
    }

    // Keep only last 1000 frames
    while (_frameMetrics.length > 1000) {
      _frameMetrics.removeAt(0);
    }

    // Log severe jank
    if (_frameMetrics.isNotEmpty) {
      final lastFrame = _frameMetrics.last;
      if (lastFrame.duration.inMilliseconds > 100 && kDebugMode) {
        developer.log(
          'Severe frame jank: ${lastFrame.duration.inMilliseconds}ms',
          name: 'PerformanceMonitor',
          level: 1000,
        );
      }
    }
  }

  void _recordMemoryUsage() {
    // This is a simplified memory recording
    // In a real implementation, you'd use platform channels to get actual memory usage
    final metric = _MemoryMetric(
      timestamp: DateTime.now(),
      usageBytes: _estimateMemoryUsage(),
    );

    _memoryMetrics.add(metric);

    // Keep only last 100 memory samples
    while (_memoryMetrics.length > 100) {
      _memoryMetrics.removeAt(0);
    }
  }

  int _estimateMemoryUsage() {
    // Usa ProcessInfo.currentRss per ottenere il RSS reale (solo native)
    try {
      return ProcessInfo.currentRss;
    } catch (_) {
      // Fallback per piattaforme non supportate (web):
      // stima basata sulle strutture dati tracciate internamente.
      final frameOverhead =
          _frameMetrics.length * 48; // ~48 bytes per FrameMetric
      final memOverhead = _memoryMetrics.length * 32;
      final metricsOverhead = _metrics.length * 128;
      return frameOverhead + memOverhead + metricsOverhead;
    }
  }
}

class _PerformanceMetric {
  final String name;
  final Stopwatch stopwatch;
  Duration? duration;

  _PerformanceMetric({required this.name, required this.stopwatch});
}

class FrameMetric {
  final DateTime timestamp;
  final Duration duration;

  FrameMetric({required this.timestamp, required this.duration});
}

class _MemoryMetric {
  final DateTime timestamp;
  final int usageBytes;

  _MemoryMetric({required this.timestamp, required this.usageBytes});
}

/// Performance statistics
class PerformanceStats {
  final double averageFrameTimeMs;
  final int jankFramesPerMinute;
  final double averageMemoryUsageMB;
  final int totalFrames;
  final bool isMonitoring;

  const PerformanceStats({
    required this.averageFrameTimeMs,
    required this.jankFramesPerMinute,
    required this.averageMemoryUsageMB,
    required this.totalFrames,
    required this.isMonitoring,
  });

  /// Get FPS approximation
  double get estimatedFPS {
    if (averageFrameTimeMs <= 0) return 60.0;
    return 1000.0 / averageFrameTimeMs;
  }

  /// Check if performance is good
  bool get isPerformanceGood {
    return averageFrameTimeMs <= 16.67 && // 60fps
        jankFramesPerMinute <= 5 &&
        averageMemoryUsageMB <= 200; // 200MB threshold
  }

  @override
  String toString() {
    return 'PerformanceStats(fps: ${estimatedFPS.toStringAsFixed(1)}, '
        'jank: $jankFramesPerMinute/min, '
        'memory: ${averageMemoryUsageMB.toStringAsFixed(1)}MB)';
  }
}

/// Mixin for widgets that need performance monitoring
mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  // The PerformanceMonitor instance is retrieved, but its lifecycle
  // (start/stop) should be managed globally, for instance by PerformanceOverlay.

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    final widget = buildWithMonitoring(context);
    stopwatch.stop();

    final buildDuration = stopwatch.elapsed;
    if (buildDuration.inMilliseconds > 16 && kDebugMode) {
      developer.log(
        'Slow build in $runtimeType: ${buildDuration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
        level: 900,
      );
    }

    return widget;
  }

  /// Override this instead of build() when using the mixin
  Widget buildWithMonitoring(BuildContext context);

  /// Time an operation within the widget
  void timeOperation(String name, VoidCallback operation) {
    PerformanceMonitor.timeSync('$runtimeType.$name', () => operation());
  }

  /// Time an async operation within the widget
  Future<TResult> timeAsyncOperation<TResult>(
    String name,
    Future<TResult> Function() operation,
  ) {
    return PerformanceMonitor.timeAsync('$runtimeType.$name', operation);
  }
}

/// Performance overlay widget for development
class PerformanceOverlay extends StatefulWidget {
  const PerformanceOverlay({
    required this.child,
    super.key,
    this.showInProduction = false,
  });

  final Widget child;
  final bool showInProduction;

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  Timer? _updateTimer;
  PerformanceStats? _stats;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();

    // Only show in debug mode unless explicitly requested
    if (kDebugMode || widget.showInProduction) {
      _monitor.startMonitoring();
      _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _stats = _monitor.stats;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if ((kDebugMode || widget.showInProduction) &&
            _showOverlay &&
            _stats != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: _buildOverlay(),
          ),
        if (kDebugMode || widget.showInProduction)
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            right: 10,
            child: FloatingActionButton.small(
              heroTag: 'performance_toggle',
              onPressed: () {
                setState(() {
                  _showOverlay = !_showOverlay;
                });
              },
              backgroundColor:
                  _stats?.isPerformanceGood == true ? Colors.green : Colors.red,
              child: const Icon(Icons.speed, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay() {
    final stats = _stats!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PERFORMANCE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: stats.isPerformanceGood ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text('FPS: ${stats.estimatedFPS.toStringAsFixed(1)}'),
            Text('Frame: ${stats.averageFrameTimeMs.toStringAsFixed(1)}ms'),
            Text('Jank: ${stats.jankFramesPerMinute}/min'),
            Text('Memory: ${stats.averageMemoryUsageMB.toStringAsFixed(1)}MB'),
            Text('Frames: ${stats.totalFrames}'),
          ],
        ),
      ),
    );
  }
}
