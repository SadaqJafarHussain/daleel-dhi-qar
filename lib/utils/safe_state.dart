import 'package:flutter/material.dart';

/// A mixin that provides safe setState and async operations for StatefulWidgets.
///
/// Prevents "setState called after dispose" errors by checking mounted state.
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with SafeStateMixin {
///   void _loadData() async {
///     final data = await fetchData();
///     safeSetState(() {
///       _data = data;
///     });
///   }
/// }
/// ```
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Calls setState only if the widget is still mounted.
  ///
  /// This prevents "setState called after dispose" errors.
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Executes an async operation and calls setState with the result only if mounted.
  ///
  /// Example:
  /// ```dart
  /// safeAsync(
  ///   () => fetchData(),
  ///   onSuccess: (data) {
  ///     _data = data;
  ///   },
  ///   onError: (error) {
  ///     _error = error.toString();
  ///   },
  /// );
  /// ```
  Future<void> safeAsync<R>({
    required Future<R> Function() operation,
    required void Function(R result) onSuccess,
    void Function(Object error)? onError,
    void Function()? onFinally,
  }) async {
    try {
      final result = await operation();
      if (mounted) {
        setState(() {
          onSuccess(result);
        });
      }
    } catch (e) {
      if (mounted && onError != null) {
        setState(() {
          onError(e);
        });
      }
    } finally {
      if (mounted && onFinally != null) {
        onFinally();
      }
    }
  }

  /// Executes a callback only if the widget is still mounted.
  void safeCallback(VoidCallback callback) {
    if (mounted) {
      callback();
    }
  }

  /// Shows a snackbar only if the widget is still mounted.
  void safeShowSnackBar(SnackBar snackBar) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  /// Navigates only if the widget is still mounted.
  Future<R?> safeNavigate<R>(Route<R> route) async {
    if (mounted) {
      return Navigator.of(context).push(route);
    }
    return null;
  }

  /// Pops the current route only if mounted.
  void safePop<R>([R? result]) {
    if (mounted) {
      Navigator.of(context).pop(result);
    }
  }
}

/// Extension on BuildContext for safe operations.
extension SafeContextExtension on BuildContext {
  /// Shows a snackbar if the context is still valid.
  void showSafeSnackBar(String message, {bool isError = false}) {
    try {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Context no longer valid, ignore
    }
  }
}
