import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Configurable base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the special alias to host loopback interface on Android Emulator
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  // Auth
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String refresh = '/auth/refresh/';
  static const String me = '/auth/me/';

  // Tasks
  static const String tasks = '/tasks/';
  static String taskDetail(int id) => '/tasks/$id/';
  static String taskStart(int id) => '/tasks/$id/start/';

  // Tracking
  static const String trackingProgress = '/tracking/progress/';

  // Wallet
  static const String wallet = '/wallet/';
  static const String walletTransactions = '/wallet/transactions/';
}
