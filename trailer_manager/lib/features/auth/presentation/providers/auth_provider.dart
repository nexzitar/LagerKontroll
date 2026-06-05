import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_storage_service.dart';
import '../../domain/entities/auth_state.dart';

/// Provider for auth storage service
final authStorageProvider = Provider<AuthStorageService>((ref) {
  final storage = AuthStorageService();
  return storage;
});

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final DioClient dioClient;
  final AuthStorageService authStorage;

  AuthNotifier(this.dioClient, this.authStorage) : super(const AuthState.initial()) {
    _checkAuth();
  }

  /// Check if user is already authenticated
  Future<void> _checkAuth() async {
    try {
      final token = authStorage.getToken();
      final user = authStorage.getUser();

      if (token != null && user != null) {
        // Set token in dio client
        dioClient.setAuthToken(token);
        state = AuthState.authenticated(user: user, token: token);
        logger.info('User already authenticated: ${user.email}');
      }
    } catch (e) {
      logger.error('Error checking auth', e);
      await authStorage.clear();
    }
  }

  /// Login with phone number and password
  Future<void> loginWithPhone(String phoneNumber, String password, {bool rememberMe = false}) async {
    try {
      state = const AuthState.loading();

      final response = await dioClient.post(
        '/auth/login',
        data: {
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        // Save to storage
        await authStorage.saveToken(token);
        await authStorage.saveUser(user);

        // Save credentials if remember me is checked
        if (rememberMe) {
          await authStorage.saveSavedCredentials(phoneNumber, password);
        } else {
          await authStorage.clearSavedCredentials();
        }

        // Set token in dio client
        dioClient.setAuthToken(token);

        state = AuthState.authenticated(user: user, token: token);
        logger.info('User logged in: $phoneNumber');
      } else {
        state = const AuthState.unauthenticated(error: 'Login failed');
      }
    } on DioException catch (e) {
      logger.error('Login error', e);
      final errorMessage = e.response?.data?['message'] ?? 'Login failed';
      state = AuthState.unauthenticated(error: errorMessage);
    } catch (e) {
      logger.error('Unexpected login error', e);
      state = const AuthState.unauthenticated(error: 'An unexpected error occurred');
    }
  }

  /// Login with email and password (legacy support)
  Future<void> login(String email, String password) async {
    try {
      state = const AuthState.loading();

      final response = await dioClient.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        // Save to storage
        await authStorage.saveToken(token);
        await authStorage.saveUser(user);

        // Set token in dio client
        dioClient.setAuthToken(token);

        state = AuthState.authenticated(user: user, token: token);
        logger.info('User logged in: ${user.email}');
      } else {
        state = const AuthState.unauthenticated(error: 'Login failed');
      }
    } on DioException catch (e) {
      logger.error('Login error', e);
      final errorMessage = e.response?.data?['message'] ?? 'Login failed';
      state = AuthState.unauthenticated(error: errorMessage);
    } catch (e) {
      logger.error('Unexpected login error', e);
      state = const AuthState.unauthenticated(error: 'An unexpected error occurred');
    }
  }

  /// Get saved credentials (for auto-fill)
  Map<String, String>? getSavedCredentials() {
    return authStorage.getSavedCredentials();
  }

  /// Register a new user
  Future<void> register(String email, String password, String name) async {
    try {
      state = const AuthState.loading();

      final response = await dioClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

        // Save to storage
        await authStorage.saveToken(token);
        await authStorage.saveUser(user);

        // Set token in dio client
        dioClient.setAuthToken(token);

        state = AuthState.authenticated(user: user, token: token);
        logger.info('User registered: ${user.email}');
      } else {
        state = const AuthState.unauthenticated(error: 'Registration failed');
      }
    } on DioException catch (e) {
      logger.error('Registration error', e);
      final errorMessage = e.response?.data?['message'] ?? 'Registration failed';
      state = AuthState.unauthenticated(error: errorMessage);
    } catch (e) {
      logger.error('Unexpected registration error', e);
      state = const AuthState.unauthenticated(error: 'An unexpected error occurred');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await authStorage.clear();
      dioClient.clearAuthToken();
      state = const AuthState.unauthenticated();
      logger.info('User logged out');
    } catch (e) {
      logger.error('Logout error', e);
    }
  }

  /// Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  final authStorage = ref.watch(authStorageProvider);
  return AuthNotifier(dioClient, authStorage);
});
