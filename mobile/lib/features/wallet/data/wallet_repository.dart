import 'package:mobile/core/constants/api_endpoints.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/features/wallet/domain/wallet_models.dart';

class WalletRepository {
  final ApiClient _api = ApiClient();

  Future<WalletModel> getWallet() async {
    final response = await _api.get(ApiEndpoints.wallet);
    return WalletModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<WalletTransactionModel>> getTransactions() async {
    final response = await _api.get(ApiEndpoints.walletTransactions);
    if (response is List) {
      return response.map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
