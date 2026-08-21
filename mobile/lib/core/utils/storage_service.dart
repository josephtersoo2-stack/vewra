import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static const String _accessTokenKey = 'vewra_access_token';
  static const String _refreshTokenKey = 'vewra_refresh_token';
  static const String _userDataKey = 'vewra_user_data';

  // Access Token
  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // Refresh Token
  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Tokens bundle
  static Future<void> saveTokens({required String access, required String refresh}) async {
    await saveAccessToken(access);
    await saveRefreshToken(refresh);
  }

  // User Data JSON string
  static Future<void> saveUserData(String jsonStr) async {
    await _storage.write(key: _userDataKey, value: jsonStr);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  // Clear all
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
