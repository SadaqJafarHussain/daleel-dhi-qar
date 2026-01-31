import 'package:flutter/material.dart';

/// Global navigation service for handling navigation from anywhere in the app
/// (including notifications, background handlers, etc.)
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  /// Global navigator key - must be set in MaterialApp
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current navigator state
  NavigatorState? get navigator => navigatorKey.currentState;

  /// Get the current context
  BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to a named route
  Future<dynamic>? pushNamed(String routeName, {Object? arguments}) {
    return navigator?.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate to a widget
  Future<dynamic>? push(Widget page) {
    return navigator?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Replace current route with a new widget
  Future<dynamic>? pushReplacement(Widget page) {
    return navigator?.pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  /// Pop the current route
  void pop<T>([T? result]) {
    navigator?.pop(result);
  }

  /// Pop until a specific condition is met
  void popUntil(bool Function(Route<dynamic>) predicate) {
    navigator?.popUntil(predicate);
  }

  /// Pop all routes and push a new one
  Future<dynamic>? pushAndRemoveUntil(Widget page) {
    return navigator?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// Check if we can pop
  bool canPop() {
    return navigator?.canPop() ?? false;
  }
}
