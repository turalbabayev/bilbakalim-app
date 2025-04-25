import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class IstatistiklerimPage extends StatefulWidget {
  const IstatistiklerimPage({super.key});

  @override
  State<IstatistiklerimPage> createState() => _IstatistiklerimPageState();
}

class _IstatistiklerimPageState extends State<IstatistiklerimPage> {
  late ScrollController _scrollController;
  bool _isLoading = true;
  
  // Kullanıcı verileri
  Map<String, dynamic> _performansVerileri = {
    'toplamSoru': 0,
    'dogruSayisi': 0,
    'yanlisSayisi': 0,
    'ortalamaSure': '0 saniye',
    'enIyiSure': '0 saniye',
    'xp': 0,
    'seviye': 1,
  };

  // Kategori başarıları ve başlıkları
  Map<String, Map<String, dynamic>> _kategoriVerileri = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadUserStats();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcının genel istatistiklerini yükle
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _performansVerileri = {
            'toplamSoru': userData['totalQuestions'] ?? 0,
            'dogruSayisi': userData['correctAnswers'] ?? 0,
            'yanlisSayisi': userData['incorrectAnswers'] ?? 0,
            'ortalamaSure': _formatDuration(Duration(seconds: userData['averageTime'] ?? 0)),
            'enIyiSure': _formatDuration(Duration(seconds: userData['bestTime'] ?? 0)),
            'xp': userData['xp'] ?? 0,
            'seviye': userData['level'] ?? 1,
          };
        });
      }

      // Kategori başarılarını yükle
      final progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .get();

      Map<String, Map<String, dynamic>> kategoriVerileri = {};
      
      // Önce tüm konuları yükle
      final konularSnapshot = await FirebaseFirestore.instance
          .collection('konular')
          .get();
      
      Map<String, String> konuBasliklari = {};
      for (var doc in konularSnapshot.docs) {
        konuBasliklari[doc.id] = doc.data()['baslik'] ?? 'Bilinmeyen Konu';
      }

      // Şimdi kullanıcının ilerlemesini işle
      for (var doc in progressSnapshot.docs) {
        final data = doc.data();
        int toplamDogru = 0;
        int toplamSoru = 0;

        data.forEach((key, value) {
          if (value is Map) {
            toplamDogru += (value['correctAnswers'] ?? 0) as int;
            toplamSoru += (value['totalQuestions'] ?? 0) as int;
          }
        });

        if (toplamSoru > 0) {
          kategoriVerileri[doc.id] = {
            'baslik': konuBasliklari[doc.id] ?? 'Bilinmeyen Konu',
            'basariOrani': toplamDogru / toplamSoru,
            'toplamDogru': toplamDogru,
            'toplamSoru': toplamSoru,
          };
        }
      }

      setState(() {
        _kategoriVerileri = kategoriVerileri;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('İstatistikler yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}s ${duration.inMinutes.remainder(60)}d';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}d ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: statusBarHeight + 12,
              bottom: 24,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.backgroundColorFistik,
                  AppTheme.backgroundColorFistik.withOpacity(0.95),
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.backgroundColorFistik.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'İstatistiklerim',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // İçerik
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B4EFF),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPerformansKarti(),
                        const SizedBox(height: 24),
                        _buildKategoriBasariKartlari(),
                        const SizedBox(height: 24),
                        _buildXPveSeviyeleme(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformansKarti() {
    final basariOrani = _performansVerileri['toplamSoru'] > 0
        ? _performansVerileri['dogruSayisi'] / _performansVerileri['toplamSoru']
        : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genel Başarı',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              CircularPercentIndicator(
                radius: 45,
                lineWidth: 10,
                percent: basariOrani,
                center: Text(
                  '${(basariOrani * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPerformansDetay(
            'Toplam Soru',
            _performansVerileri['toplamSoru'].toString(),
            Icons.question_answer_outlined,
          ),
          const SizedBox(height: 12),
          _buildPerformansDetay(
            'Doğru',
            _performansVerileri['dogruSayisi'].toString(),
            Icons.check_circle_outline,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildPerformansDetay(
            'Yanlış',
            _performansVerileri['yanlisSayisi'].toString(),
            Icons.highlight_off,
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          _buildPerformansDetay(
            'Ortalama Süre',
            _performansVerileri['ortalamaSure'],
            Icons.timer_outlined,
          ),
          const SizedBox(height: 12),
          _buildPerformansDetay(
            'En İyi Süre',
            _performansVerileri['enIyiSure'],
            Icons.speed,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformansDetay(String baslik, String deger, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Text(
          baslik,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          deger,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriBasariKartlari() {
    if (_kategoriVerileri.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Henüz hiç soru çözülmemiş',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori Başarıları',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ..._kategoriVerileri.entries.map((entry) {
          final kategoriData = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          kategoriData['baslik'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(kategoriData['basariOrani'] * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${kategoriData['toplamDogru']}/${kategoriData['toplamSoru']} soru',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearPercentIndicator(
                    padding: EdgeInsets.zero,
                    lineHeight: 8,
                    percent: kategoriData['basariOrani'],
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    progressColor: AppTheme.primaryColor,
                    barRadius: const Radius.circular(4),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildXPveSeviyeleme() {
    final xp = _performansVerileri['xp'] as int;
    final seviye = _performansVerileri['seviye'] as int;
    final sonrakiSeviyeXP = seviye * 1000; // Her seviye için 1000 XP gerekiyor
    final seviyeIlerlemesi = (xp % 1000) / 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seviye $seviye',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$xp XP',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 8,
            percent: seviyeIlerlemesi,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            progressColor: AppTheme.primaryColor,
            barRadius: const Radius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            'Sonraki seviye: ${xp % 1000}/$sonrakiSeviyeXP XP',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 