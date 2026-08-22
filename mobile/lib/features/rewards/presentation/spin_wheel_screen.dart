import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';
import 'package:mobile/core/network/api_client.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _wheelAnimation;
  double _currentAngle = 0;
  bool _canSpin = true;
  bool _isSpinning = false;
  bool _isLoading = true;

  final List<Color> _segmentColors = const [
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFEAB308),
    Color(0xFFA855F7),
  ];

  final List<String> _segmentLabels = const [
    '1🪙', '5🪙', '10🪙', '25🪙', '50🪙', '100🪙',
    '500🪙', '1000🪙', '❄️Freeze', '2x XP', '🎁Box', '5000🪙'
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _checkSpinStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkSpinStatus() async {
    try {
      final res = await ApiClient().get('/rewards/spin-status/');
      if (mounted) {
        setState(() {
          _canSpin = res['can_spin'] ?? true;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _spinWheel() async {
    if (!_canSpin || _isSpinning) return;
    setState(() => _isSpinning = true);

    try {
      final res = await ApiClient().post('/rewards/daily-spin/');
      final data = res;
      final int segmentLanded = (data['segment_landed'] ?? 1) as int;

      // Calculate target angle to stop on segment
      final segmentAngle = (2 * pi) / 12;
      final targetSegmentOffset = (segmentLanded - 1) * segmentAngle;
      final fullRotations = 5 * 2 * pi;
      final targetAngle = fullRotations + (2 * pi - targetSegmentOffset);

      _wheelAnimation = Tween<double>(
        begin: _currentAngle,
        end: _currentAngle + targetAngle,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

      _animController.forward(from: 0).then((_) {
        setState(() {
          _currentAngle = (_currentAngle + targetAngle) % (2 * pi);
          _isSpinning = false;
          _canSpin = false;
        });
        _showPrizeDialog(data['label'] ?? 'Prize Won!');
      });
    } catch (e) {
      setState(() => _isSpinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Daily spin already used today!'),
        ),
      );
    }
  }

  void _showPrizeDialog(String prizeLabel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.primaryLight),
        ),
        title: const Center(
          child: Text('🎉 Congratulations!', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎰', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'You Won:',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              prizeLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppColors.coinGold,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Spin Wheel'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Status Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.ticket_fill, color: AppColors.coinGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _canSpin ? '1 Free Spin Available' : '0 Free Spins Available',
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Wheel with Top Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Animated Rotating Wheel
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          final angle = _isSpinning ? _wheelAnimation.value : _currentAngle;
                          return Transform.rotate(
                            angle: angle,
                            child: SizedBox(
                              width: 300,
                              height: 300,
                              child: CustomPaint(
                                painter: _WheelPainter(
                                  colors: _segmentColors,
                                  labels: _segmentLabels,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Center SPIN Button
                      GestureDetector(
                        onTap: _spinWheel,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'SPIN',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Top Pointer Indicator
                      Positioned(
                        top: 0,
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 40,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Footer Info
                  Text(
                    '⭐ Spin daily and win bonus coins, freezes, and jackpots!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Color> colors;
  final List<String> labels;

  _WheelPainter({required this.colors, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = (2 * pi) / colors.length;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i];
      final startAngle = i * sweepAngle;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Draw segment border
      final borderPaint = Paint()
        ..color = const Color(0xFF1E2638)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      // Draw Label Text
      canvas.save();
      final textAngle = startAngle + sweepAngle / 2;
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);

      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius * 0.55, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
