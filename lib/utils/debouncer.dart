import 'dart:async';

import 'package:flutter/material.dart';

/// A utility class that prevents rapid button clicks by debouncing actions.
///
/// Usage example:
/// ```dart
/// // In your widget state
/// final _debouncer = Debouncer();
///
/// // In your button
/// ElevatedButton(
///   onPressed: () => _debouncer.run(() {
///     // Your action here
///   }),
///   child: Text('Submit'),
/// )
///
/// // Don't forget to dispose
/// @override
/// void dispose() {
///   _debouncer.dispose();
///   super.dispose();
/// }
/// ```
class Debouncer {
  /// The delay duration before the action can be triggered again.
  final Duration delay;

  Timer? _timer;
  bool _isReady = true;

  /// Creates a debouncer with an optional [delay].
  ///
  /// Default delay is 500 milliseconds.
  Debouncer({Duration? delay}) : delay = delay ?? const Duration(milliseconds: 500);

  /// Creates a debouncer with a delay specified in milliseconds.
  factory Debouncer.milliseconds(int milliseconds) {
    return Debouncer(delay: Duration(milliseconds: milliseconds));
  }

  /// Returns true if the debouncer is ready to accept a new action.
  bool get isReady => _isReady;

  /// Runs the given [action] if the debouncer is ready.
  ///
  /// After running, the debouncer will be locked for the duration of [delay].
  void run(VoidCallback action) {
    if (_isReady) {
      _isReady = false;
      action();
      _timer = Timer(delay, () {
        _isReady = true;
      });
    }
  }

  /// Runs the given async [action] if the debouncer is ready.
  ///
  /// The debouncer will remain locked until the action completes or
  /// the delay passes, whichever is longer.
  Future<void> runAsync(Future<void> Function() action) async {
    if (_isReady) {
      _isReady = false;
      try {
        await action();
      } finally {
        _timer = Timer(delay, () {
          _isReady = true;
        });
      }
    }
  }

  /// Wraps a callback to be debounced.
  ///
  /// Useful for passing directly to onPressed:
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: _debouncer.wrap(() => doSomething()),
  ///   child: Text('Submit'),
  /// )
  /// ```
  VoidCallback? wrap(VoidCallback? action) {
    if (action == null) return null;
    return () => run(action);
  }

  /// Resets the debouncer, allowing the next action to run immediately.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _isReady = true;
  }

  /// Cancels any pending timer and cleans up resources.
  ///
  /// Call this in your widget's dispose method.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// A mixin that provides debouncing functionality to StatefulWidgets.
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with DebouncerMixin {
///   void _onButtonPressed() {
///     debounce(() {
///       // Your action here
///     });
///   }
/// }
/// ```
mixin DebouncerMixin<T extends StatefulWidget> on State<T> {
  final Debouncer _debouncer = Debouncer();

  /// The debouncer instance. Override to customize the delay.
  Debouncer get debouncer => _debouncer;

  /// Runs the action with debouncing.
  void debounce(VoidCallback action) {
    _debouncer.run(action);
  }

  /// Runs the async action with debouncing.
  Future<void> debounceAsync(Future<void> Function() action) {
    return _debouncer.runAsync(action);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}

/// Extension on VoidCallback to easily add debouncing.
extension DebouncedCallback on VoidCallback {
  /// Returns a debounced version of this callback.
  ///
  /// Note: Each call creates a new Debouncer, so this is best used
  /// with a stored Debouncer instance for consistent behavior.
  VoidCallback debounced([Duration delay = const Duration(milliseconds: 500)]) {
    final debouncer = Debouncer(delay: delay);
    return () => debouncer.run(this);
  }
}
