import 'package:bilbakalim/services/graphics_services.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' show pi;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class TestCompletionPage extends StatefulWidget {
  final int correct;
  final int uncorrect;
  final String konuIndex;
  final String altkonuIndex;
  final String elapsedTime;
  final int totalQuestions;
  
  const TestCompletionPage({
    super.key,
    required this.correct,
    required this.uncorrect,
    required this.konuIndex,
    required this.altkonuIndex,
    required this.elapsedTime,
    required this.totalQuestions,
  });

  @override
  State<TestCompletionPage> createState() => _TestCompletionPageState();
}

class _TestCompletionPageState extends State<TestCompletionPage> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final percentage = widget.totalQuestions > 0 
        ? (widget.correct / widget.totalQuestions * 100)
        : 0.0;

    _progressAnimation = Tween<double>(
      begin: 0,
      end: percentage,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    if (percentage >= 70) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.totalQuestions > 0 
        ? (widget.correct / widget.totalQuestions * 100)
        : 0.0;
    final isSuccessful = percentage >= 70;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Arkaplan Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  isSuccessful ? const Color(0xFFF1F8E9) : const Color(0xFFFBE9E7),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Modern AppBar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          saveGraphic(widget.correct, widget.uncorrect, 
                            widget.konuIndex.toString(), widget.altkonuIndex.toString());
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black87,
                            size: 24,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.elapsedTime,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Ana İçerik
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Başarı Yüzdesi Animasyonu
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isSuccessful
                                  ? [
                                      const Color(0xFF4CAF50).withOpacity(0.9),
                                      const Color(0xFF66BB6A),
                                    ]
                                  : [
                                      const Color(0xFFEF5350).withOpacity(0.9),
                                      const Color(0xFFE57373),
                                    ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: (isSuccessful ? Colors.green : Colors.red).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Başarı İkonu
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isSuccessful ? Icons.emoji_events : Icons.psychology,
                                          color: isSuccessful ? Colors.amber : Colors.orange,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getBasariBaslik(percentage),
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getBasariMesaji(percentage),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.white.withOpacity(0.9),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Yüzde Göstergesi
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    AnimatedBuilder(
                                      animation: _progressAnimation,
                                      builder: (context, child) {
                                        return SizedBox(
                                          width: 120,
                                          height: 120,
                                          child: CircularProgressIndicator(
                                            value: _progressAnimation.value / 100,
                                            strokeWidth: 10,
                                            backgroundColor: Colors.white.withOpacity(0.2),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.white.withOpacity(0.9),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _progressAnimation,
                                          builder: (context, child) {
                                            return Text(
                                              '${_progressAnimation.value.toInt()}%',
                                              style: GoogleFonts.poppins(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            );
                                          },
                                        ),
                                        Text(
                                          'Başarı',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // İstatistik Kartları
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Detaylı Sonuçlar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.check_circle_outline,
                                        iconColor: const Color(0xFF4CAF50),
                                        backgroundColor: const Color(0xFFE8F5E9),
                                        value: widget.correct.toString(),
                                        label: 'Doğru',
                                        textColor: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.cancel_outlined,
                                        iconColor: const Color(0xFFEF5350),
                                        backgroundColor: const Color(0xFFFBE9E7),
                                        value: widget.uncorrect.toString(),
                                        label: 'Yanlış',
                                        textColor: const Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.timer_outlined,
                                        iconColor: AppTheme.primaryColor,
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                        value: widget.elapsedTime,
                                        label: 'Süre',
                                        textColor: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        icon: Icons.quiz_outlined,
                                        iconColor: const Color(0xFF9C27B0),
                                        backgroundColor: const Color(0xFFF3E5F5),
                                        value: widget.totalQuestions.toString(),
                                        label: 'Toplam',
                                        textColor: const Color(0xFF6A1B9A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Ana Sayfaya Dön Butonu
                          _buildHomeButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String value,
    required String label,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getBasariBaslik(double percentage) {
    if (percentage >= 90) {
      return 'Muhteşem!';
    } else if (percentage >= 70) {
      return 'Tebrikler!';
    } else if (percentage >= 50) {
      return 'İyi Deneme!';
    } else if (percentage >= 30) {
      return 'Geliştirebilirsin!';
    } else {
      return 'Daha Çok Çalışmalısın!';
    }
  }

  String _getBasariMesaji(double percentage) {
    if (percentage >= 90) {
      return 'Mükemmel bir performans gösterdin! Böyle devam et!';
    } else if (percentage >= 70) {
      return 'Çok iyi bir sonuç elde ettin, başarıların devamını dileriz!';
    } else if (percentage >= 50) {
      return 'İyi gidiyorsun, biraz daha pratik yaparak daha da gelişebilirsin.';
    } else if (percentage >= 30) {
      return 'Düzenli çalışarak performansını artırabilirsin.';
    } else {
      return 'Endişelenme, düzenli pratik yaparak kendini geliştirebilirsin.';
    }
  }

  Widget _buildHomeButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ana Sayfaya Dön',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
