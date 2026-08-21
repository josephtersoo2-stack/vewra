import 'dart:convert';
import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/utils/storage_service.dart';
import 'package:mobile/features/auth/domain/user_model.dart';

class AuthRepository {
  final ApiClient _api = ApiClient();

  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    final tokens = response['tokens'] as Map<String, dynamic>;
    final userJson = response['user'] as Map<String, dynamic>;

    await StorageService.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    await StorageService.saveUserData(jsonEncode(userJson));

    return UserModel.fromJson(userJson);
  }

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await _api.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    final tokens = response['tokens'] as Map<String, dynamic>;
    final userJson = response['user'] as Map<String, dynamic>;

    await StorageService.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    await StorageService.saveUserData(jsonEncode(userJson));

    return UserModel.fromJson(userJson);
  }

  Future<UserModel> getMe() async {
    final response = await _api.get(ApiEndpoints.me);
    final user = UserModel.fromJson(response as Map<String, dynamic>);
    await StorageService.saveUserData(jsonEncode(user.toJson()));
    return user;
  }

  Future<UserModel?> getCachedUser() async {
    final userStr = await StorageService.getUserData();
    if (userStr != null) {
      try {
        return UserModel.fromJson(jsonDecode(userStr));
      } catch (_) {}
    }
    return null;
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }
}
