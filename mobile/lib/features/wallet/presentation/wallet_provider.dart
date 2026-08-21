import 'package:flutter/material.dart';
import 'package:mobile/core/network/api_exception.dart';
import 'package:mobile/features/wallet/data/wallet_repository.dart';
import 'package:mobile/features/wallet/domain/wallet_models.dart';

class WalletProvider extends ChangeNotifier {
  final WalletRepository _repo = WalletRepository();

  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWalletData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final walletData = await _repo.getWallet();
      final txData = await _repo.getTransactions();

      _wallet = walletData;
      _transactions = txData;
      _isLoading = false;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load wallet: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
}
