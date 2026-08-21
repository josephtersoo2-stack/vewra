import 'package:flutter/foundation.dart';


class ApiEndpoints {
  // Host IP of PC on local Wi-Fi for physical phone testing
  static const String serverHost = '192.168.1.45';
  static const int serverPort = 8001;

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:$serverPort/api/v1';
    }
    // Used by physical Android devices & emulators on local network
    return 'http://$serverHost:$serverPort/api/v1';
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
