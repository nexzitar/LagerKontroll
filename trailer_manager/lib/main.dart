import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/network/dio_client.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/auth/data/services/auth_storage_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/browse/presentation/screens/trailer_list_screen.dart';
import 'features/module_tracking/presentation/screens/module_capture_screen.dart';
import 'features/module_tracking/presentation/screens/module_review_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  logger.init();
  logger.info('Starting Trailer Manager App v${AppConstants.appVersion}');

  // Initialize Dio client
  dioClient.init();
  logger.info('Dio client initialized');

  // Initialize Hive
  await Hive.initFlutter();
  logger.info('Hive initialized');

  // Open Hive boxes
  await Hive.openBox(AppConstants.settingsBoxName);
  await Hive.openBox(AppConstants.cacheBoxName);
  logger.info('Hive boxes opened');

  // Initialize auth storage
  final authStorage = AuthStorageService();
  await authStorage.init();
  logger.info('Auth storage initialized');

  // Set auth storage in DioClient for token expiry handling
  dioClient.setAuthStorage(authStorage);

  logger.info('App initialization complete');

  // Create ProviderContainer for accessing providers from non-widget code
  final container = ProviderContainer(
    overrides: [
      authStorageProvider.overrideWithValue(authStorage),
    ],
  );

  // Set token expiry callback to clear auth state
  dioClient.setTokenExpiredCallback(() {
    final authNotifier = container.read(authProvider.notifier);
    authNotifier.logout();
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrailerManagerApp(),
    ),
  );
}

class TrailerManagerApp extends ConsumerWidget {
  const TrailerManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      navigatorKey: navigationService.navigatorKey,
      scaffoldMessengerKey: navigationService.scaffoldMessengerKey,
      home: authState.isAuthenticated ? const TrailerListScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/module-capture': (context) => const ModuleCaptureScreen(),
        '/module-review': (context) => const ModuleReviewScreen(),
      },
    );
  }
}
