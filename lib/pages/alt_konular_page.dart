import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/services/fetch_titles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:bilbakalim/pages/bolumler/test_screen/question_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilbakalim/pages/premium_page.dart';

class AltKonularPage extends StatefulWidget {
  final String konuId;
  final String konuBaslik;

  const AltKonularPage({
    required this.konuId,
    required this.konuBaslik,
    Key? key,
  }) : super(key: key);

  @override
  _AltKonularPageState createState() => _AltKonularPageState();
}

class _AltKonularPageState extends State<AltKonularPage> {
  late DatabaseReference _databaseRef;
  Map<String, dynamic>? _cachedData;
  final String _cacheKey = 'alt_konular_';
  bool _isPremium = false;
  List<String> _sortedKeys = [];
  Map<String, Map<String, dynamic>> _cozulenSorular = {};
  String? _userId;

  // Statik soru sayıları
  final Map<String, int> _konuSoruSayilari = {
    '-OKAdBq7LH6PXcW457aN': 2020,
    '-OKAk2EbpC1xqSwbJbYM': 800,
    '-OKw6fKcYGunlY_PbCo3': 415,
    '-OMBcE1I9DRj8uvlYSmH': 650,
    '-OMhpwKF1PZ0-QnjyJm8': 1050,
    '-OMlVD6ufbDvCgZhfz8N': 900,
  };

  @override
  void initState() {
    super.initState();
    _databaseRef = FirebaseDatabase.instance.ref('konular/${widget.konuId}/altkonular');
    _loadData();
    _checkPremiumStatus();
    _loadUserProgress();
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        setState(() {
          _isPremium = userData.data()?['isPremium'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Premium durumu kontrol edilirken hata: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('konular')
          .doc(widget.konuId)
          .collection('altkonular')
          .get();

      if (snapshot.docs.isNotEmpty) {
        Map<String, dynamic> convertedData = {};
        
        for (var doc in snapshot.docs) {
          convertedData[doc.id] = {
            'baslik': doc.data()['baslik'] ?? '',
            'soruSayisi': doc.data()['soruSayisi'] ?? 0,
          };
        }

        setState(() {
          _cachedData = convertedData;
          _sortedKeys = convertedData.keys.toList()..sort();
        });
      }
    } catch (e) {
      debugPrint('Veri yüklenirken hata: $e');
      if (_cachedData == null) {
        setState(() {
          _cachedData = {};
          _sortedKeys = [];
        });
      }
    }
  }

  Future<void> _loadUserProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final progressDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(widget.konuId)
          .get();

      if (progressDoc.exists) {
        final data = progressDoc.data();
        if (data != null) {
          setState(() {
            _cozulenSorular = {};
            data.forEach((key, value) {
              if (value is Map<dynamic, dynamic>) {
                // Dynamic map'i String, dynamic map'e dönüştür
                final convertedMap = Map<String, dynamic>.fromEntries(
                  value.entries.map((e) => MapEntry(e.key.toString(), e.value))
                );
                _cozulenSorular[key] = convertedMap;
              } else if (value is Map) {
                // Diğer map türleri için güvenli dönüşüm
                _cozulenSorular[key] = Map<String, dynamic>.from(value);
              }
            });
          });
        }
      }
    } catch (e) {
      debugPrint('Kullanıcı ilerlemesi yüklenirken hata: $e');
    }
  }

  Future<void> _showPremiumDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Premium Üyelik Gerekli',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/dersResimleri/premium.png',
              width: 48,
              height: 48,
              color: Color(0xFFFFD700),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu konudaki sorulara erişmek için premium üyelik gerekiyor.',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor.withOpacity(0.7),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PremiumPage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Premium\'a Yükselt',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Widget _buildProgressInfo(String altKonuId, Map<String, dynamic> altKonuData) {
    final progress = _cozulenSorular[altKonuId];
    // Toplam soru sayısını progress'ten al, yoksa altKonuData'dan al
    final totalQuestions = progress != null ? (progress['totalQuestions'] ?? 0) : 0;
    
    // Progress değerlerini güvenli bir şekilde al
    final solvedQuestions = progress != null ? (progress['solvedQuestions'] ?? 0) : 0;
    final correctAnswers = progress != null ? (progress['correctAnswers'] ?? 0) : 0;
    final incorrectAnswers = progress != null ? (progress['incorrectAnswers'] ?? 0) : 0;
    
    // Progress değerini hesapla
    final progressValue = totalQuestions > 0 ? (solvedQuestions / totalQuestions).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$solvedQuestions/$totalQuestions',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.primaryColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (solvedQuestions > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$correctAnswers',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.highlight_off,
                color: Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '$incorrectAnswers',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final soruSayisi = _konuSoruSayilari[widget.konuId] ?? 0;
    
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
                    Expanded(
                      child: Text(
                        widget.konuBaslik,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_cachedData != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_sortedKeys.length} Alt Konu',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.question_answer_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$soruSayisi Soru',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // İçerik
          Expanded(
            child: _cachedData == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6B4EFF),
                    ),
                  )
                : _cachedData!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz alt konu bulunmuyor',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _sortedKeys.length,
                        itemBuilder: (context, index) {
                          final key = _sortedKeys[index];
                          final entry = MapEntry(key, _cachedData![key]);
                          final isFirstThree = index < 3;
                          final isLocked = !isFirstThree && !_isPremium;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () async {
                                if (isLocked) {
                                  await _showPremiumDialog();
                                  return;
                                }
                                
                                debugPrint('Alt konu seçildi: ${entry.value['baslik']}');
                                debugPrint('Bölüm ID: ${widget.konuId}');
                                debugPrint('Alt Konu ID: ${entry.key}');
                                
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuestionPage(
                                      bolumIndex: widget.konuId,
                                      altKonuIndex: entry.key,
                                      lastQuestionIndex: _cozulenSorular[entry.key]?['lastQuestionIndex'] ?? 0,
                                    ),
                                  ),
                                ).then((_) => _loadUserProgress());
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.value['baslik'] ?? 'Başlıksız',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: isLocked 
                                                    ? AppTheme.primaryColor.withOpacity(0.5)
                                                    : AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isLocked)
                                          Image.asset(
                                            'assets/dersResimleri/premium.png',
                                            width: 22,
                                            height: 22,
                                            color: Color(0xFFFFD700),
                                          ),
                                        const SizedBox(width: 8),
                                        if (isLocked)
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: AppTheme.primaryColor.withOpacity(0.5),
                                            size: 16,
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: AppTheme.primaryColor.withOpacity(0.5),
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isLocked) ...[
                                      _buildProgressInfo(entry.key, entry.value),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 