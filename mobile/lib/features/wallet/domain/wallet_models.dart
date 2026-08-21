class WalletTransactionModel {
  final int id;
  final double amount;
  final double balanceAfter;
  final String transactionType;
  final String description;
  final String? referenceId;
  final String createdAt;

  WalletTransactionModel({
    required this.id,
    required this.amount,
    required this.balanceAfter,
    required this.transactionType,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      id: json['id'] as int,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      balanceAfter: (json['balance_after'] is num)
          ? (json['balance_after'] as num).toDouble()
          : double.tryParse(json['balance_after']?.toString() ?? '0') ?? 0.0,
      transactionType: json['transaction_type'] as String? ?? 'watch_reward',
      description: json['description'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class WalletModel {
  final int id;
  final double balance;
  final String updatedAt;
  final List<WalletTransactionModel> recentTransactions;

  WalletModel({
    required this.id,
    required this.balance,
    required this.updatedAt,
    this.recentTransactions = const [],
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as int? ?? 0,
      balance: (json['balance'] is num)
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      updatedAt: json['updated_at'] as String? ?? '',
      recentTransactions: (json['recent_transactions'] as List<dynamic>?)
              ?.map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
