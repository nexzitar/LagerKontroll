import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';

/// State for user management
class UserManagementState {
  final List<User> users;
  final bool isLoading;
  final String? error;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// User management notifier (for admin operations)
class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final DioClient dioClient;

  UserManagementNotifier(this.dioClient) : super(const UserManagementState());

  /// Get all users (admin only)
  Future<void> getAllUsers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await dioClient.get('/auth/users');

      if (response.statusCode == 200 && response.data != null) {
        final usersList = (response.data as List)
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(
          users: usersList,
          isLoading: false,
        );
        logger.info('Fetched ${usersList.length} users');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch users',
        );
      }
    } on DioException catch (e) {
      logger.error('Error fetching users', e);
      final errorMessage = e.response?.data?['message'] ?? 'Failed to fetch users';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    } catch (e) {
      logger.error('Unexpected error fetching users', e);
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  /// Create a new user (admin only)
  Future<bool> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await dioClient.post(
        '/auth/users',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final newUser = UserModel.fromJson(response.data as Map<String, dynamic>);

        // Add new user to the list
        state = state.copyWith(
          users: [newUser, ...state.users],
        );

        logger.info('User created: ${newUser.email}');
        return true;
      } else {
        state = state.copyWith(error: 'Failed to create user');
        return false;
      }
    } on DioException catch (e) {
      logger.error('Error creating user', e);
      final errorMessage = e.response?.data?['message'] ?? 'Failed to create user';
      state = state.copyWith(error: errorMessage);
      return false;
    } catch (e) {
      logger.error('Unexpected error creating user', e);
      state = state.copyWith(error: 'An unexpected error occurred');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for user management
final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return UserManagementNotifier(dioClient);
});
