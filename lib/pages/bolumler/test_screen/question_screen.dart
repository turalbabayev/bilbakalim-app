import 'package:bilbakalim/pages/bolumler/test_screen/result.dart';
import 'package:bilbakalim/services/questions_services.dart';
import 'package:bilbakalim/styles/text_styles.dart';
import 'package:bilbakalim/components/html_content_viewer.dart';
import 'package:bilbakalim/components/game_background.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bilbakalim/services/firebase_auth_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilbakalim/pages/premium_page.dart';
import 'dart:convert';

class QuestionPage extends StatefulWidget {
  final String altKonuIndex;
  final String bolumIndex;
  final String? altdalIndex;
  final List<Map<String, dynamic>>? sorular;
  final int? testSuresi;
  final int lastQuestionIndex;

  const QuestionPage({
    super.key,
    required this.altKonuIndex,
    required this.bolumIndex,
    this.altdalIndex,
    this.sorular,
    this.testSuresi,
    this.lastQuestionIndex = 0,
  });

  @override
  _QuestionPageState createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _optionKeys = {};
  final Map<String, Uint8List> _imageCache = {}; // Resim cache'i için
  int _currentQuestionIndex = 0;
  int correct = 0;
  int notcorrect = 0;
  String? _selectedAnswer;
  bool _isCorrect = false;
  bool _isAnswered = false;
  bool _isLiked = false;
  bool _isUnliked = false;
  bool isFavourite = false;
  bool _hasPurchased = false;
  bool _isReported = false;
  bool _isPremium = false;
  bool _isFirstSubtopic = false;
  bool _showCharacterAnimation = false;
  bool _isLoading = true;
  String? _characterImage;
  double? _characterStartX;
  double? _characterStartY;
  double? _characterEndX;
  double? _characterEndY;

  late ConfettiController _confettiController;
  late SharedPreferences _prefs;

  List<Map<String, dynamic>> _questions = [];
  int _totalQuestions = 0;

  bool _initialized = false;

  // Timer değişkenleri
  late Timer _timer;
  Duration _gecenSure = Duration.zero;
  bool _testBitti = false;

  // Firestore referansı
  late FirebaseFirestore _firestore;

  // İlerleme için yeni değişkenler
  late String? _userId;
  late String _progressId;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startTimer();
    _loadInteractionStates();
    _loadCharacterImage();
    _firestore = FirebaseFirestore.instance;
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _progressId = widget.bolumIndex;
    _currentQuestionIndex = widget.lastQuestionIndex;
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _initialize() async {
    try {
      // Önce premium durumunu kontrol et
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

      // Sonra ilk alt konu mu kontrol et
      final altKonularRef = _firestore
          .collection('konular')
          .doc(widget.bolumIndex)
          .collection('altkonular');
      
      final altKonularSnapshot = await altKonularRef.get();
      final altKonular = altKonularSnapshot.docs;
      
      if (altKonular.isNotEmpty) {
        altKonular.sort((a, b) => a.id.compareTo(b.id));
        final currentIndex = altKonular.indexWhere((doc) => doc.id == widget.altKonuIndex);
        setState(() {
          _isFirstSubtopic = currentIndex < 3; // İlk 3 alt konu için true
        });
      }

      // Premium değilse ve ilk 3 alt konudan biri değilse
      if (!_isPremium && !_isFirstSubtopic) {
        if (!mounted) return;
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              'Premium Üyelik Gerekli',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
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
                    color: AppTheme.textColor.withOpacity(0.7),
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
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(
                  'İptal',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.mainGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
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
        return;
      }

      // Kontroller tamamlandıktan sonra soruları yükle
      await _initializeQuestions();

    } catch (e) {
      debugPrint('Başlatma sırasında hata: $e');
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Future<void> _initializeQuestions() async {
    try {
      List<Map<String, dynamic>> questions;
      
      if (widget.sorular != null) {
        questions = widget.sorular!;
      } else if (widget.altdalIndex != null) {
        questions = await fetch_subquestions(
          widget.bolumIndex,
          widget.altKonuIndex,
          widget.altdalIndex!,
        );
      } else {
        questions = await fetch_questions(
          widget.bolumIndex,
          widget.altKonuIndex,
        );
      }

      if (!mounted) return;

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu konuda henüz soru bulunmamaktadır.'),
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }

      questions.sort((a, b) => (a['soruNumarasi'] as int).compareTo(b['soruNumarasi'] as int));
      
      setState(() {
        _questions = questions;
        _totalQuestions = questions.length;
        _isLoading = false;
      });

      // İlerleme kontrolü
      if (_userId != null) {
        final progressDoc = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('progress')
            .doc(_progressId)
            .get();

      if (!mounted) return;

        if (progressDoc.exists) {
          final data = progressDoc.data();
          if (data != null && data[widget.altKonuIndex] != null) {
            final altKonuData = data[widget.altKonuIndex] as Map<String, dynamic>;
            final lastQuestionIndex = altKonuData['lastQuestionIndex'] ?? 0;
            final correctAnswers = altKonuData['correctAnswers'] ?? 0;
            final incorrectAnswers = altKonuData['incorrectAnswers'] ?? 0;

            final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
              builder: (context) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
                  backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Column(
              children: [
                Icon(
                        Icons.bookmark_added_rounded,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                        'Kaldığın Yerden Devam Et',
                        textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                          color: Colors.black87,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                        'Toplam ${_questions.length} sorudan:',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStatCard(
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            value: correctAnswers,
                            label: 'Doğru',
                          ),
                          const SizedBox(width: 16),
                          _buildStatCard(
                            icon: Icons.highlight_off,
                            color: Colors.red,
                            value: incorrectAnswers,
                            label: 'Yanlış',
                          ),
                        ],
                      ),
                const SizedBox(height: 16),
                Text(
                        '${lastQuestionIndex + 1}. sorudasın.',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                      onPressed: () async {
                        // Firestore'daki ilerlemeyi sıfırla
                        if (_userId != null) {
                          try {
                            await _firestore
                                .collection('users')
                                .doc(_userId)
                                .collection('progress')
                                .doc(_progressId)
                                .set({
                                  widget.altKonuIndex: {
                                    'totalQuestions': _totalQuestions,
                                    'solvedQuestions': 0,
                                    'correctAnswers': 0,
                                    'incorrectAnswers': 0,
                                    'lastQuestionIndex': 0,
                                    'lastUpdated': FieldValue.serverTimestamp(),
                                  }
                                }, SetOptions(merge: true));

                            // Mevcut oturum bilgisini sil
                            await _firestore
                                .collection('users')
                                .doc(_userId)
                                .collection('currentSessions')
                                .doc('${widget.bolumIndex}_${widget.altKonuIndex}')
                                .delete();
                          } catch (e) {
                            debugPrint('İlerleme sıfırlanırken hata: $e');
                          }
                        }

                        // Local state'i sıfırla
                        setState(() {
                          _currentQuestionIndex = 0;
                          correct = 0;
                          notcorrect = 0;
                          _isLoading = false;
                        });
                        Navigator.pop(context, false);
                },
                child: Text(
                        'Baştan Başla',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.mainGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentQuestionIndex = lastQuestionIndex;
                              correct = correctAnswers;
                              notcorrect = incorrectAnswers;
                              _isLoading = false;
                            });
                            Navigator.pop(context, true);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text(
                              'Devam Et',
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
              ),
            );
          } else {
            // İlk defa başlıyor
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Column(
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Yeni Test Başlıyor',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bu konuya ilk defa başlıyorsun!',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppTheme.textColor.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toplam ${_questions.length} soru var.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.mainGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentQuestionIndex = 0;
                              correct = 0;
                              notcorrect = 0;
                              _isLoading = false;
                            });
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Text(
                              'Başla',
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
                  actionsAlignment: MainAxisAlignment.center,
                ),
              ),
            );
          }
        } else {
          // İlk defa başlıyor (progress dokümanı yok)
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Column(
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yeni Test Başlıyor',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bu konuya ilk defa başlıyorsun!',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                    color: AppTheme.textColor.withOpacity(0.7),
                  ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toplam ${_questions.length} soru var.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
              Container(
                margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.mainGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                        onTap: () {
                          setState(() {
                            _currentQuestionIndex = 0;
                            correct = 0;
                            notcorrect = 0;
                            _isLoading = false;
                          });
                          Navigator.pop(context);
                        },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text(
                            'Başla',
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
                actionsAlignment: MainAxisAlignment.center,
          ),
        ),
      );
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Sorular yüklenirken hata: $e');
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _gecenSure += const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${hours == "00" ? "" : "$hours:"}$minutes:$seconds";
  }

  void _navigateToResults() {
    if (!mounted) return;
    _timer.cancel();
    
    // Testi bitirince ilerlemeyi sıfırla
    _resetProgress();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestCompletionPage(
          correct: correct,
          uncorrect: notcorrect,
          konuIndex: widget.bolumIndex,
          altkonuIndex: widget.altKonuIndex,
          elapsedTime: _formatDuration(_gecenSure),
          totalQuestions: _totalQuestions,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Etkileşim durumlarını yükle
  Future<void> _loadInteractionStates() async {
    if (_questions.isEmpty) return;
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final String questionId = currentQuestion['id'];
    final String konuId = widget.bolumIndex;
    final String altKonuId = widget.altKonuIndex;
    
    try {
      final doc = await _firestore
          .collection('konular')
          .doc(konuId)
          .collection('altkonular')
          .doc(altKonuId)
          .collection('sorular')
          .doc(questionId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        setState(() {
          _isLiked = data?['liked'] ?? false;
          _isUnliked = data?['unliked'] ?? false;
          _isReported = data?['reported'] ?? false;
        });
      }
    } catch (e) {
      print('Etkileşim durumları yüklenirken hata: $e');
    }
  }

  // Etkileşim durumunu güncelle
  Future<void> _updateInteractionState(String field, bool value) async {
    if (_questions.isEmpty) return;
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final String questionId = currentQuestion['id'];
    final String konuId = widget.bolumIndex;
    final String altKonuId = widget.altKonuIndex;
    
    try {
      await _firestore
          .collection('konular')
          .doc(konuId)
          .collection('altkonular')
          .doc(altKonuId)
          .collection('sorular')
          .doc(questionId)
          .update({field: value});
    } catch (e) {
      print('Etkileşim durumu güncellenirken hata: $e');
      // Hata durumunda state'i geri al
      setState(() {
        switch (field) {
          case 'liked':
            _isLiked = !value;
            break;
          case 'unliked':
            _isUnliked = !value;
            break;
          case 'reported':
            _isReported = !value;
            break;
        }
      });
    }
  }

  // Soruyu paylaş
  void _shareQuestion() {
    if (_questions.isEmpty) return;
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final String questionText = currentQuestion['soruMetni'];
    
    Share.share(
      'Bil Bakalım uygulamasından bir soru:\n\n$questionText',
      subject: 'Bil Bakalım - Soru Paylaşımı',
    );
  }

  // Etkileşim butonu widget'ı
  Widget _buildInteractionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Future<void> _loadCharacterImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        setState(() {
          _characterImage = userData.data()?['character']?['image'];
        });
      }
    } catch (e) {
      debugPrint('Karakter resmi yüklenirken hata: $e');
    }
  }

  Future<void> _loadProgress() async {
    if (_userId == null) return;

    try {
      final progressDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('progress')
          .doc(_progressId)
          .get();

      if (progressDoc.exists) {
        final data = progressDoc.data();
        if (data != null && data[widget.altKonuIndex] != null) {
          final altKonuData = data[widget.altKonuIndex] as Map<String, dynamic>;
          final lastQuestionIndex = altKonuData['lastQuestionIndex'] ?? 0;
          final correctAnswers = altKonuData['correctAnswers'] ?? 0;
          final incorrectAnswers = altKonuData['incorrectAnswers'] ?? 0;

          if (!mounted) return;

          final shouldContinue = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Column(
                  children: [
                    Icon(
                      Icons.bookmark_added_rounded,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kaldığın Yerden Devam Et',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Toplam ${_questions.length} sorudan:',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatCard(
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                          value: correctAnswers,
                          label: 'Doğru',
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          icon: Icons.highlight_off,
                          color: Colors.red,
                          value: incorrectAnswers,
                          label: 'Yanlış',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${lastQuestionIndex + 1}. sorudasın.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: Text(
                      'Vazgeç',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.mainGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context, true);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Text(
                            'Devam Et',
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
            ),
          );

          if (shouldContinue == true) {
            setState(() {
              _currentQuestionIndex = lastQuestionIndex;
              correct = correctAnswers;
              notcorrect = incorrectAnswers;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('İlerleme yüklenirken hata: $e');
    }
  }

  Future<void> _saveProgress() async {
    if (_userId == null) return;

    try {
      final progressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('progress')
          .doc(widget.bolumIndex);

      final progressData = {
        widget.altKonuIndex: {
          'solvedQuestions': _currentQuestionIndex + 1,
          'correctAnswers': correct,
          'incorrectAnswers': notcorrect,
          'lastQuestionIndex': _currentQuestionIndex,
        }
      };

      await progressRef.set(progressData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('İlerleme kaydedilirken hata: $e');
    }
  }

  Future<void> _resetProgress() async {
    if (_userId == null) return;

    try {
      // Mevcut oturum bilgisini sil
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('currentSessions')
          .doc('${widget.bolumIndex}_${widget.altKonuIndex}')
          .delete();

      // İlerleme bilgisini sıfırla
      setState(() {
        _currentQuestionIndex = 0;
        correct = 0;
        notcorrect = 0;
        _selectedAnswer = null;
        _isAnswered = false;
        _showCharacterAnimation = false;
        _gecenSure = Duration.zero;
      });
    } catch (e) {
      debugPrint('İlerleme sıfırlanırken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion['cevaplar'] as List;

    // Her soru ve seçenek için benzersiz key'ler oluştur
    _optionKeys.clear(); // Önceki key'leri temizle
    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      _optionKeys[option] = GlobalKey(debugLabel: 'option_${_currentQuestionIndex}_${i}_$option');
    }

    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Arkaplan
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
            ),

            // Ana İçerik
            Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Üst Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Geri Butonu
                          GestureDetector(
                            onTap: _showExitConfirmationDialog,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          // Süre
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.timer_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDuration(_gecenSure),
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // İlerleme Göstergesi
                      Container(
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: _currentQuestionIndex + 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: _totalQuestions - (_currentQuestionIndex + 1),
                              child: Container(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Soru Numaraları
                      SizedBox(
                        height: 44,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _totalQuestions,
                          itemBuilder: (context, index) {
                            final bool isAnswered = index < _currentQuestionIndex || _isAnswered && index == _currentQuestionIndex;
                            final bool isCurrent = index == _currentQuestionIndex;
                            
                            return GestureDetector(
                              onTap: () {
                                if (_isAnswered || index < _currentQuestionIndex) {
                                  setState(() => _currentQuestionIndex = index);
                                }
                              },
                              child: Container(
                                width: 36,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? Colors.white
                                      : isAnswered
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCurrent ? Colors.white : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: isCurrent ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ] : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrent
                                          ? AppTheme.primaryColor
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Soru ve Cevaplar
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Soru Kartı
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Soru Numarası
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Soru ${_currentQuestionIndex + 1}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    // Soru Resmi (eğer varsa)
                                    if (currentQuestion['soruResmi'] != null && currentQuestion['soruResmi'].toString().isNotEmpty) ...[
                                      Container(
                                        width: double.infinity,
                                        constraints: BoxConstraints(
                                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: _buildQuestionImage(currentQuestion['soruResmi']),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    // Soru Metni
                                    HtmlContentViewer(
                                      htmlContent: currentQuestion['soruMetni'],
                                      textColor: AppTheme.textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.6,
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Cevap Seçenekleri
                        ...options.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final String optionValue = entry.value;
                          final bool isSelected = optionValue == _selectedAnswer;
                          final bool isCorrectAnswer = _isAnswered && optionValue == currentQuestion['dogruCevap'];

                          Color backgroundColor = Colors.white;
                          Color borderColor = Colors.grey[300]!;
                          Color textColor = AppTheme.textColor;

                          if (_isAnswered) {
                            if (isSelected && _isCorrect) {
                              backgroundColor = const Color(0xFFE8F5E9);
                              borderColor = const Color(0xFF4CAF50);
                              textColor = const Color(0xFF2E7D32);
                            } else if (isSelected && !_isCorrect) {
                              backgroundColor = const Color(0xFFFFEBEE);
                              borderColor = const Color(0xFFEF5350);
                              textColor = const Color(0xFFD32F2F);
                            } else if (optionValue == currentQuestion['dogruCevap'] && !_isCorrect) {
                              backgroundColor = const Color(0xFFE8F5E9);
                              borderColor = const Color(0xFF4CAF50);
                              textColor = const Color(0xFF2E7D32);
                            }
                          } else if (isSelected) {
                            backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
                            borderColor = AppTheme.primaryColor;
                            textColor = AppTheme.primaryColor;
                          }

                          return Padding(
                            key: _optionKeys[optionValue],
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isAnswered ? null : () => _checkAnswer(optionValue, currentQuestion['dogruCevap']),
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isSelected || (isCorrectAnswer && _isAnswered)
                                              ? borderColor
                                              : Colors.grey[100],
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: borderColor.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + index),
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected || (isCorrectAnswer && _isAnswered)
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: HtmlContentViewer(
                                          htmlContent: optionValue,
                                          textColor: textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      if (_isAnswered)
                                        Row(
                                          children: [
                                            if (isSelected && !_isCorrect)
                                              const Icon(
                                                Icons.cancel_outlined,
                                                color: Color(0xFFEF5350),
                                          size: 24,
                                              )
                                            else if (optionValue == currentQuestion['dogruCevap'] && !_isCorrect && _characterImage != null)
                                              TweenAnimationBuilder<double>(
                                                duration: const Duration(milliseconds: 800),
                                                curve: Curves.elasticOut,
                                                tween: Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                builder: (context, value, child) {
                                                  return Transform.scale(
                                                    scale: value,
                                                    child: Transform.rotate(
                                                      angle: 2 * 3.14159 * value,
                                                      child: Container(
                                                        margin: const EdgeInsets.only(left: 8),
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: const Color(0xFF4CAF50).withOpacity(0.3 * value),
                                                              blurRadius: 12 * value,
                                                              spreadRadius: 2 * value,
                                                            ),
                                                          ],
                                                        ),
                                                        child: ClipOval(
                                                          child: Image.asset(
                                                            _characterImage!,
                                                            width: 32,
                                                            height: 32,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              )
                                            else if (isCorrectAnswer && _isCorrect)
                                              const Icon(
                                                Icons.check_circle_outline,
                                                color: Color(0xFF4CAF50),
                                                size: 24,
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),

                        if (_isAnswered) ...[
                          const SizedBox(height: 24),
                          // Açıklama Kartı
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _isCorrect
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _isCorrect
                                    ? const Color(0xFF4CAF50)
                                    : const Color(0xFFEF5350),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isCorrect
                                          ? Icons.check_circle_outline
                                          : Icons.error_outline,
                                      color: _isCorrect
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFFD32F2F),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isCorrect ? 'Doğru Cevap!' : 'Yanlış Cevap',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _isCorrect
                                            ? const Color(0xFF2E7D32)
                                            : const Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ],
                                ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                if (_characterImage != null && _isAnswered) ...[
                                  Center(
                                    child: TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.elasticOut,
                                      tween: Tween<double>(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.scale(
                                          scale: value,
                                          child: Container(
                                            width: 64,
                                            height: 64,
                                            margin: const EdgeInsets.only(bottom: 16),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (_isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFEF5350))
                                                      .withOpacity(0.3 * value),
                                                  blurRadius: 12 * value,
                                                  spreadRadius: 2 * value,
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: Image.asset(
                                                _characterImage!,
                                                width: 64,
                                                height: 64,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                  HtmlContentViewer(
                                    htmlContent: currentQuestion['aciklama'],
                                    textColor: _isCorrect
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFD32F2F),
                                    fontSize: 15,
                                    height: 1.5,
                                    textAlign: TextAlign.left,
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Navigasyon Butonları
                        Row(
                          children: [
                            if (_currentQuestionIndex > 0)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _goToPreviousQuestion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_back, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Önceki Soru',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_currentQuestionIndex > 0 && _currentQuestionIndex < _totalQuestions - 1)
                              const SizedBox(width: 12),
                            if (_currentQuestionIndex == _totalQuestions - 1)
                              // Son soru için "Testi Bitir" butonu
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        title: Column(
                                          children: [
                                            Icon(
                                              Icons.check_circle_outline,
                                              size: 48,
                                              color: const Color(0xFF4CAF50),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Testi Bitirmek İstiyor musun?',
                                              style: GoogleFonts.poppins(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textColor,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Toplam $_totalQuestions sorudan:',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                color: AppTheme.textColor.withOpacity(0.7),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  color: const Color(0xFF4CAF50),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '$correct doğru',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 15,
                                                    color: const Color(0xFF4CAF50),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(
                                              'Geri Dön',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: AppTheme.textColor.withOpacity(0.7),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                            decoration: BoxDecoration(
                                              gradient: AppTheme.mainGradient,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.pop(context);
                                                  _navigateToResults();
                                                },
                                                borderRadius: BorderRadius.circular(12),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                  child: Text(
                                                    'Testi Bitir',
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
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Testi Bitir',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle_outline, size: 20),
                                    ],
                                  ),
                                ),
                              )
                            else if (_currentQuestionIndex < _totalQuestions - 1)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _goToNextQuestion,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sonraki Soru',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                maxBlastForce: 5,
                minBlastForce: 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
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
          ],
        ),
      ),
    );
  }

  void _checkAnswer(String selectedOption, String correctAnswer) {
    // Seçilen cevabın indeksini bul (A, B, C, D)
    final options = _questions[_currentQuestionIndex]['cevaplar'] as List;
    final selectedIndex = options.indexOf(selectedOption);
    final selectedLetter = String.fromCharCode(65 + selectedIndex); // A=65, B=66, C=67, D=68

    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedOption;
      // Hem seçenek metni hem de harf olarak kontrol et
      _isCorrect = selectedOption == correctAnswer || selectedLetter == correctAnswer;

      if (_isCorrect) {
        _confettiController.play();
        correct++;
      } else {
        notcorrect++;
      }
    });

    // İlerlemeyi kaydet
    _updateProgress();

    // Açıklamaya scroll yapma
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _updateProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Alt konu için çözülen soru sayısını güncelle
      final userProgressRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('progress')
          .doc(widget.bolumIndex);

      // Kategori başarıları için referans
      final userStatsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stats')
          .doc('categories');

      // İlerleme bilgisini güncelle
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Alt konu ilerlemesi için
        final docSnapshot = await transaction.get(userProgressRef);
        Map<String, dynamic> data = {};
        if (docSnapshot.exists) {
          final docData = docSnapshot.data();
          if (docData != null) {
            data = Map<String, dynamic>.from(docData);
          }
        }
        
        // Alt konu için ilerleme bilgisini güncelle
        if (!data.containsKey(widget.altKonuIndex)) {
          data[widget.altKonuIndex] = {
            'totalQuestions': _questions.length,
            'solvedQuestions': _currentQuestionIndex + 1,
            'correctAnswers': correct,
            'incorrectAnswers': notcorrect,
            'lastQuestionIndex': _currentQuestionIndex,
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        } else {
          final altKonuData = Map<String, dynamic>.from(data[widget.altKonuIndex] as Map);
          final previousSolved = altKonuData['solvedQuestions'];
          final oldSolvedQuestions = previousSolved is int ? previousSolved : 0;
          final solvedQuestions = math.max(
            oldSolvedQuestions,
            _currentQuestionIndex + 1
          );
          
          data[widget.altKonuIndex] = {
            'totalQuestions': _questions.length,
            'solvedQuestions': solvedQuestions,
            'correctAnswers': correct,
            'incorrectAnswers': notcorrect,
            'lastQuestionIndex': _currentQuestionIndex,
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        }

        // Kategori başarılarını güncelle
        final statsSnapshot = await transaction.get(userStatsRef);
        Map<String, dynamic> statsData = statsSnapshot.exists ? 
            Map<String, dynamic>.from(statsSnapshot.data() ?? {}) : {};

        // Kategori başarısını hesapla
        if (!statsData.containsKey(widget.bolumIndex)) {
          statsData[widget.bolumIndex] = {
            'totalQuestions': _questions.length,
            'solvedQuestions': 1,
            'correctAnswers': _isCorrect ? 1 : 0,
            'incorrectAnswers': _isCorrect ? 0 : 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        } else {
          final konuData = Map<String, dynamic>.from(statsData[widget.bolumIndex] as Map);
          final totalQuestions = (konuData['totalQuestions'] as num?)?.toInt() ?? 0;
          
          statsData[widget.bolumIndex] = {
            'totalQuestions': math.max(totalQuestions, _questions.length),
            'solvedQuestions': ((konuData['solvedQuestions'] as num?)?.toInt() ?? 0) + 1,
            'correctAnswers': ((konuData['correctAnswers'] as num?)?.toInt() ?? 0) + (_isCorrect ? 1 : 0),
            'incorrectAnswers': ((konuData['incorrectAnswers'] as num?)?.toInt() ?? 0) + (_isCorrect ? 0 : 1),
            'lastUpdated': FieldValue.serverTimestamp(),
          };
        }

        // Verileri kaydet
        transaction.set(userProgressRef, data);
        transaction.set(userStatsRef, statsData);
      });

      // Kullanıcının mevcut oturum ilerlemesini kaydet
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('currentSessions')
          .doc('${widget.bolumIndex}_${widget.altKonuIndex}')
          .set({
            'currentQuestion': _currentQuestionIndex,
            'correct': correct,
            'incorrect': notcorrect,
            'totalQuestions': _questions.length,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

    } catch (e) {
      debugPrint('İlerleme kaydedilirken hata: $e');
    }
  }

  void _showExitConfirmationDialog() {
    if (!mounted) return;
    
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: const Color(0xFFFF9800),
              ),
              const SizedBox(height: 16),
              Text(
                'Testten Çıkmak İstiyor musun?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Testten çıkarsan ilerleme kaydedilmeyecek.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Emin misin?',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Devam Et',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor.withOpacity(0.7),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEDED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Text(
                      'Testten Çık',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    );
  }

  void _goToPreviousQuestion() {
    setState(() {
      _currentQuestionIndex--;
      _selectedAnswer = null;
      _isAnswered = false;
    });
  }

  void _goToNextQuestion() {
    setState(() {
      _currentQuestionIndex++;
      _selectedAnswer = null;
      _isAnswered = false;
      _showCharacterAnimation = false;
    });
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required int value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage(String imageData) {
    if (_imageCache.containsKey(imageData)) {
      // Cache'den resmi göster
      return Image.memory(
        _imageCache[imageData]!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageError();
        },
      );
    }

    try {
      if (imageData.startsWith('data:image')) {
        // Base64 formatındaki resmi ayıkla ve cache'le
        final base64String = imageData.split(',')[1];
        final decodedImage = base64Decode(base64String);
        _imageCache[imageData] = decodedImage;
        
        return Image.memory(
          decodedImage,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError();
          },
        );
      } else {
        // Normal URL ise
        return Image.network(
          imageData,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImageError();
          },
        );
      }
    } catch (e) {
      return _buildImageError();
    }
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      color: Colors.grey[100],
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}

