import 'package:hive/hive.dart';
import '../models/user_model.dart';

/// Service for storing and retrieving authentication data
class AuthStorageService {
  static const String _boxName = 'auth';
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _savedPhoneKey = 'saved_phone';
  static const String _savedPasswordKey = 'saved_password';

  late Box _box;

  /// Initialize the auth storage
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _box.put(_tokenKey, token);
  }

  /// Get saved authentication token
  String? getToken() {
    return _box.get(_tokenKey) as String?;
  }

  /// Save user data
  Future<void> saveUser(UserModel user) async {
    await _box.put(_userKey, user.toJson());
  }

  /// Get saved user data
  UserModel? getUser() {
    final userData = _box.get(_userKey);
    if (userData == null) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(userData as Map));
  }

  /// Check if user is authenticated (has valid token)
  bool isAuthenticated() {
    return getToken() != null;
  }

  /// Save credentials for auto-login (Remember Me)
  Future<void> saveSavedCredentials(String phoneNumber, String password) async {
    await _box.put(_savedPhoneKey, phoneNumber);
    await _box.put(_savedPasswordKey, password);
  }

  /// Get saved credentials for auto-fill
  Map<String, String>? getSavedCredentials() {
    final phone = _box.get(_savedPhoneKey) as String?;
    final password = _box.get(_savedPasswordKey) as String?;

    if (phone != null && password != null) {
      return {'phoneNumber': phone, 'password': password};
    }
    return null;
  }

  /// Clear saved credentials
  Future<void> clearSavedCredentials() async {
    await _box.delete(_savedPhoneKey);
    await _box.delete(_savedPasswordKey);
  }

  /// Clear all authentication data (logout)
  Future<void> clear() async {
    await _box.delete(_tokenKey);
    await _box.delete(_userKey);
    // Keep saved credentials for next login
  }

  /// Close the storage
  Future<void> close() async {
    await _box.close();
  }
}
