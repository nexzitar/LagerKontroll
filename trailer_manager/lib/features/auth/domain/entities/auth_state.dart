import 'user.dart';

/// Authentication state
class AuthState {
  final User? user;
  final String? token;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  const AuthState.initial()
      : user = null,
        token = null,
        isAuthenticated = false,
        isLoading = false,
        error = null;

  const AuthState.loading()
      : user = null,
        token = null,
        isAuthenticated = false,
        isLoading = true,
        error = null;

  const AuthState.authenticated({
    required User user,
    required String token,
  })  : user = user,
        token = token,
        isAuthenticated = true,
        isLoading = false,
        error = null;

  const AuthState.unauthenticated({String? error})
      : user = null,
        token = null,
        isAuthenticated = false,
        isLoading = false,
        error = error;

  AuthState copyWith({
    User? user,
    String? token,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
