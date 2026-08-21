import 'package:flutter/material.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/domain/user_model.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final cachedUser = await _repo.getCachedUser();
      if (cachedUser != null) {
        _user = cachedUser;
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Refresh user in background
        try {
          _user = await _repo.getMe();
          notifyListeners();
        } catch (_) {}
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repo.login(username: username, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _repo.register(username: username, email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred: ${e.toString()}';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  void updateBalance(double newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(walletBalance: newBalance);
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      _user = await _repo.getMe();
      notifyListeners();
    } catch (_) {}
  }

  void updateWalletBalance(double newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(walletBalance: newBalance);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

