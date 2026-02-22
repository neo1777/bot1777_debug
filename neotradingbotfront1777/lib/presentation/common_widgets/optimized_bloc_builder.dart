import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Optimized BlocBuilder that prevents unnecessary rebuilds by using
/// precise buildWhen conditions and const constructors where possible
class OptimizedBlocBuilder<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  const OptimizedBlocBuilder({
    required this.builder,
    super.key,
    this.bloc,
    this.buildWhen,
    this.throttleDuration,
  });

  final BlocWidgetBuilder<S> builder;
  final B? bloc;
  final BlocBuilderCondition<S>? buildWhen;
  final Duration? throttleDuration;

  @override
  State<OptimizedBlocBuilder<B, S>> createState() =>
      _OptimizedBlocBuilderState<B, S>();
}

class _OptimizedBlocBuilderState<B extends StateStreamable<S>, S>
    extends State<OptimizedBlocBuilder<B, S>> {
  DateTime? _lastBuildTime;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      bloc: widget.bloc,
      buildWhen: (previous, current) {
        // Apply throttling if specified
        if (widget.throttleDuration != null) {
          final now = DateTime.now();
          if (_lastBuildTime != null &&
              now.difference(_lastBuildTime!) < widget.throttleDuration!) {
            return false;
          }
          _lastBuildTime = now;
        }

        // Apply custom buildWhen condition if provided
        if (widget.buildWhen != null) {
          return widget.buildWhen!(previous, current);
        }

        // Default behavior - only rebuild if state actually changed
        return previous != current;
      },
      builder: widget.builder,
    );
  }
}

/// Optimized BlocListener that prevents unnecessary listeners from firing
class OptimizedBlocListener<B extends StateStreamable<S>, S>
    extends StatefulWidget {
  const OptimizedBlocListener({
    required this.listener,
    required this.child,
    super.key,
    this.bloc,
    this.listenWhen,
    this.throttleDuration,
  });

  final BlocWidgetListener<S> listener;
  final Widget child;
  final B? bloc;
  final BlocListenerCondition<S>? listenWhen;
  final Duration? throttleDuration;

  @override
  State<OptimizedBlocListener<B, S>> createState() =>
      _OptimizedBlocListenerState<B, S>();
}

class _OptimizedBlocListenerState<B extends StateStreamable<S>, S>
    extends State<OptimizedBlocListener<B, S>> {
  DateTime? _lastListenTime;

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      bloc: widget.bloc,
      listenWhen: (previous, current) {
        // Apply throttling if specified
        if (widget.throttleDuration != null) {
          final now = DateTime.now();
          if (_lastListenTime != null &&
              now.difference(_lastListenTime!) < widget.throttleDuration!) {
            return false;
          }
          _lastListenTime = now;
        }

        // Apply custom listenWhen condition if provided
        if (widget.listenWhen != null) {
          return widget.listenWhen!(previous, current);
        }

        // Default behavior - only listen if state actually changed
        return previous != current;
      },
      listener: widget.listener,
      child: widget.child,
    );
  }
}

/// Performance-optimized widget that combines const constructor optimization
/// with conditional rebuilding
class OptimizedWidget extends StatelessWidget {
  const OptimizedWidget({required this.builder, super.key, this.condition});

  final Widget Function() builder;
  final bool Function()? condition;

  @override
  Widget build(BuildContext context) {
    // Only rebuild if condition is true or not provided
    if (condition != null && !condition!()) {
      return const SizedBox.shrink();
    }

    return builder();
  }
}

/// Mixin to add performance monitoring to widgets
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  DateTime? _buildStartTime;
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildStartTime = DateTime.now();
    _buildCount++;

    final widget = buildOptimized(context);

    if (_buildStartTime != null) {
      final buildDuration = DateTime.now().difference(_buildStartTime!);

      // Log performance warnings for slow builds in debug mode
      if (buildDuration.inMilliseconds > 16) {
        // ~60fps threshold
        debugPrint(
          'Build lento $runtimeType: ${buildDuration.inMilliseconds}ms (#$_buildCount)',
        );
      }
    }

    return widget;
  }

  /// Override this instead of build() when using the mixin
  Widget buildOptimized(BuildContext context);
}

/// Optimized scroll controller that reduces rebuild frequency
class OptimizedScrollController extends ScrollController {
  OptimizedScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    this.throttleDuration = const Duration(milliseconds: 16),
  });

  final Duration throttleDuration;
  DateTime? _lastNotificationTime;
  bool _pendingNotification = false;

  @override
  void notifyListeners() {
    // Throttle scroll notifications to reduce rebuild frequency
    final now = DateTime.now();
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < throttleDuration) {
      // Invece di droppare l'evento, schedula una notifica differita
      // per non perdere la posizione finale dello scroll
      if (!_pendingNotification) {
        _pendingNotification = true;
        Future.delayed(throttleDuration, () {
          _pendingNotification = false;
          if (hasListeners) {
            _lastNotificationTime = DateTime.now();
            super.notifyListeners();
          }
        });
      }
      return;
    }

    _lastNotificationTime = now;
    super.notifyListeners();
  }
}

/// Optimized version of AnimatedBuilder that reduces rebuilds
class OptimizedAnimatedBuilder extends StatefulWidget {
  const OptimizedAnimatedBuilder({
    required this.animation,
    required this.builder,
    super.key,
    this.child,
    this.throttleDuration = const Duration(milliseconds: 16),
  });

  final Listenable animation;
  final TransitionBuilder builder;
  final Widget? child;
  final Duration throttleDuration;

  @override
  State<OptimizedAnimatedBuilder> createState() =>
      _OptimizedAnimatedBuilderState();
}

class _OptimizedAnimatedBuilderState extends State<OptimizedAnimatedBuilder> {
  DateTime? _lastBuildTime;

  void _listener() {
    // Throttle animation rebuilds
    final now = DateTime.now();
    if (_lastBuildTime != null &&
        now.difference(_lastBuildTime!) < widget.throttleDuration) {
      return;
    }

    _lastBuildTime = now;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_listener);
  }

  @override
  void didUpdateWidget(OptimizedAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation.removeListener(_listener);
      widget.animation.addListener(_listener);
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}
