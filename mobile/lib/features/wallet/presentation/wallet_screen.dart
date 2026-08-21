import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/features/auth/presentation/auth_provider.dart';
import 'package:mobile/features/wallet/presentation/wallet_provider.dart';
import 'package:mobile/features/wallet/presentation/widgets/balance_card.dart';
import 'package:mobile/features/wallet/presentation/widgets/transaction_tile.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchWalletData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final user = authProvider.user;

    final currentBalance = walletProvider.wallet?.balance ?? user?.walletBalance ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh, size: 20),
            onPressed: () => walletProvider.fetchWalletData(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await walletProvider.fetchWalletData();
          await authProvider.refreshUser();
        },
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              BalanceCard(balance: currentBalance),
              const SizedBox(height: 28),

              // Transaction History Header
              const Row(
                children: [
                  Icon(CupertinoIcons.list_bullet, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Reward History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (walletProvider.isLoading && walletProvider.transactions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (walletProvider.transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(CupertinoIcons.money_dollar_circle, color: AppColors.textMuted, size: 44),
                      SizedBox(height: 12),
                      Text(
                        'No Transactions Yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Complete YouTube video tasks to earn your first coins!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: walletProvider.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = walletProvider.transactions[index];
                    return TransactionTile(transaction: tx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
