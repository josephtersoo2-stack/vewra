import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/api_client.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  bool _isLoading = true;
  bool _canScratch = true;
  bool _isScratched = false;
  List<String> _revealedGrid = List.filled(9, '❓');
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final res = await ApiClient().get('/rewards/scratch-status/');
      if (mounted) {
        setState(() {
          _canScratch = res['can_scratch'] ?? true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revealCard() async {
    if (!_canScratch || _isScratched) return;

    try {
      final res = await ApiClient().post('/rewards/daily-scratch/');
      final data = res;
      final List<dynamic> grid = data['grid'] ?? [];

      final symbolMap = {
        'coin_common': '🪙',
        'coin_rare': '💰',
        'xp': '⚡',
        'freeze': '❄️',
        'mystery': '🎁',
      };

      if (mounted) {
        setState(() {
          _revealedGrid = grid.map((e) => symbolMap[e] ?? '🪙').toList();
          _isScratched = true;
          _canScratch = false;
          _resultData = data;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Daily Scratch Card already claimed today!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Scratch Card'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Match 2 or 3 symbols to win big rewards!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3x3 Scratch Card Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: _revealCard,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: _isScratched
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.surfaceElevated,
                                        AppColors.surfaceLight,
                                      ],
                                    )
                                  : AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isScratched ? AppColors.primaryLight : Colors.white24,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _revealedGrid[index],
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_isScratched)
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _canScratch ? _revealCard : null,
                        child: Text(
                          _canScratch ? 'Scratch All Panels' : 'Already Played Today',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else if (_resultData != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Column(
                        children: [
                          const Text('🎉 YOU MATCHED & WON!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(
                            '+${_resultData!['coins_earned']} Coins | +${_resultData!['xp_earned']} XP',
                            style: GoogleFonts.outfit(
                              color: AppColors.coinGold,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
