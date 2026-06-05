import 'package:flutter/material.dart';

/// Global navigation service to allow navigation from non-widget code
/// Used by DioClient to navigate to login on token expiry
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Navigate to a named route, replacing the current stack
  void navigateToAndClearStack(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
    );
  }

  /// Show a snackbar message
  void showSnackBar(String message, {Color? backgroundColor}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.orange,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Global instance for easy access
final navigationService = NavigationService();
