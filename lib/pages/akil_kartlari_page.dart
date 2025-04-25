import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bilbakalim/pages/kaydedilen_kartlar_page.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilbakalim/pages/premium_page.dart';

class AkilKartlariPage extends StatefulWidget {
  final String konuId;
  final String konuBaslik;

  const AkilKartlariPage({
    Key? key,
    required this.konuId,
    required this.konuBaslik,
  }) : super(key: key);

  @override
  State<AkilKartlariPage> createState() => _AkilKartlariPageState();
}

class _AkilKartlariPageState extends State<AkilKartlariPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _cards = [];
  ValueNotifier<Offset> _position = ValueNotifier(Offset.zero);
  double _angle = 0;
  int _currentIndex = 0;
  bool _isDragging = false;
  bool _isLoading = true;
  bool _showTutorial = true;
  bool _isPremium = false;
  late AnimationController _tutorialController;
  late Animation<Offset> _tutorialAnimation;
  Set<String> _savedCardIds = {};

  final List<List<Color>> gradientRenkler = [
    [
      const Color(0xFF434CDC),
      const Color(0xFF686EDD),
    ],
    [
      const Color(0xFFFF6B6B),
      const Color(0xFFFF8E8E),
    ],
    [
      const Color(0xFF4ECDC4),
      const Color(0xFF6EE7E7),
    ],
    [
      const Color(0xFFFFBE0B),
      const Color(0xFFFFD93D),
    ],
    [
      const Color(0xFF8338EC),
      const Color(0xFF9D68E7),
    ],
    [
      const Color(0xFFFF006E),
      const Color(0xFFFF4D8D),
    ],
    [
      const Color(0xFF3A86FF),
      const Color(0xFF5B9FFF),
    ],
    [
      const Color(0xFF38B000),
      const Color(0xFF57CC2E),
    ],
    [
      const Color(0xFFFF477E),
      const Color(0xFFFF71A2),
    ],
    [
      const Color(0xFF7209B7),
      const Color(0xFF9B42D1),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _loadCards().then((_) {
      _loadSavedIndex();
    });
    _loadUserPremiumStatus();
    
    // Tutorial animasyonu için controller
    _tutorialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Sağa sola kaydırma animasyonu
    _tutorialAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0.3, 0),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.3, 0),
          end: const Offset(-0.3, 0),
        ),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(-0.3, 0),
          end: const Offset(0, 0),
        ),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _tutorialController,
      curve: Curves.easeInOut,
    ));

    // Animasyonu başlat
    _tutorialController.repeat();

    // 5 saniye sonra tutorial'ı gizle
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showTutorial = false;
        });
        _tutorialController.stop();
      }
    });
  }

  @override
  void dispose() {
    _tutorialController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPremiumStatus() async {
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

  Future<void> _loadCards() async {
    try {
      final cardsSnapshot = await FirebaseFirestore.instance
          .collection('miniCards-konular')
          .doc(widget.konuId)
          .collection('cards')
          .get();

      final List<Map<String, dynamic>> loadedCards = [];
      
      for (var doc in cardsSnapshot.docs) {
        final cardData = doc.data();
        String content = cardData['content'] ?? '';
        // HTML etiketlerini temizle
        content = content.replaceAll(RegExp(r'<[^>]*>'), '');
        
        final Map<String, dynamic> card = {
          'baslik': cardData['altKonu'] ?? '',
          'aciklama': content,
          'kartNo': cardData['kartNo'] ?? 0,
          'konu': widget.konuBaslik,
        };

        if (cardData['resim'] != null && cardData['resimTuru'] != null) {
          card['resim'] = cardData['resim'];
          card['resimTuru'] = cardData['resimTuru'];
        }

        loadedCards.add(card);
      }

      // Kartları kartNo'ya göre sırala
      loadedCards.sort((a, b) => (a['kartNo'] as int).compareTo(b['kartNo'] as int));

      setState(() {
        _cards = loadedCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Kartlar yüklenirken hata: $e');
    }
  }

  Future<void> _saveCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('card_index_${widget.konuId}', _currentIndex);
  }

  Future<void> _loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('card_index_${widget.konuId}') ?? 0;
    if (savedIndex < _cards.length) {
      setState(() {
        _currentIndex = savedIndex;
      });
    }
  }

  Future<void> _loadSavedCards() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCards = prefs.getStringList('saved_cards') ?? [];
    setState(() {
      _savedCardIds = savedCards.toSet();
    });
  }

  Future<void> _toggleSaveCard(String cardId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedCards = prefs.getStringList('saved_cards') ?? [];
    final cardSet = savedCards.toSet();

    setState(() {
      if (_savedCardIds.contains(cardId)) {
        _savedCardIds.remove(cardId);
        cardSet.remove(cardId);
      } else {
        _savedCardIds.add(cardId);
        cardSet.add(cardId);
      }
    });

    await prefs.setStringList('saved_cards', cardSet.toList());

    // Firestore'a kaydetme
    try {
      final userId = 'CURRENT_USER_ID'; // Kullanıcı ID'sini buraya ekleyin
      final cardData = _cards[_currentIndex];
      
      if (_savedCardIds.contains(cardId)) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saved_cards')
            .doc(cardId)
            .set({
          'cardId': cardId,
          'konuId': widget.konuId,
          'konuBaslik': widget.konuBaslik,
          'baslik': cardData['baslik'],
          'aciklama': cardData['aciklama'],
          'kartNo': cardData['kartNo'],
          'resim': cardData['resim'],
          'resimTuru': cardData['resimTuru'],
          'savedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('saved_cards')
            .doc(cardId)
            .delete();
      }
    } catch (e) {
      debugPrint('Kart kaydedilirken hata: $e');
    }
  }

  void _showPremiumDialog() {
    showDialog(
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
              'Bu kartı görüntülemek için premium üyelik gerekiyor. Premium üye olarak tüm kartlara erişebilirsiniz.',
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
            onPressed: () => Navigator.pop(context),
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
              color: AppTheme.primaryColor,
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

  void _goToNextCard() {
    if (_currentIndex < _cards.length - 1) {
      // Premium kontrolü
      if (!_isPremium && _currentIndex >= 29) {
        _showPremiumDialog();
        return;
      }
      
      setState(() {
        _currentIndex++;
        _saveCurrentIndex();
      });
    }
  }

  void _goToPreviousCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _saveCurrentIndex();
      });
    }
  }

  void _resetCards() {
    setState(() {
      _position.value = Offset.zero;
      _angle = 0;
      _isDragging = false;
    });
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _position.value = Offset.zero;
      _angle = 0;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position.value += details.delta;
      _angle = _position.value.dx / 20;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final threshold = MediaQuery.of(context).size.width / 4;
    if (_position.value.dx.abs() > threshold) {
      double screenWidth = MediaQuery.of(context).size.width;
      _position.value = Offset(
        _position.value.dx.sign * screenWidth * 2,
        _position.value.dy,
      );
      setState(() {
        // Premium kontrolü
        if (_position.value.dx > 0 && !_isPremium && _currentIndex >= 29) {
          _showPremiumDialog();
          _resetCards();
          return;
        }
        
        if (_position.value.dx > 0) {
          _goToNextCard();
        } else {
          _goToPreviousCard();
        }
        _isDragging = false;
        _position.value = Offset.zero;
        _angle = 0;
      });
    } else {
      setState(() {
        _position.value = Offset.zero;
        _angle = 0;
        _isDragging = false;
      });
    }
  }

  int _getColorIndex(int cardIndex) {
    return cardIndex % gradientRenkler.length;
  }

  Widget _buildCard({
    required Map<String, dynamic> card,
    required double cardHeight,
    required bool isTop,
    ValueNotifier<Offset>? position,
    required double scale,
    required double angle,
    required double yOffset,
    required bool isDragging,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.85;
    final fixedCardHeight = screenHeight * 0.7;
    final cardId = '${widget.konuId}_${card['kartNo']}';

    return ValueListenableBuilder<Offset>(
      valueListenable: position ?? ValueNotifier(Offset.zero),
      builder: (context, offset, child) {
        return AnimatedPositioned(
          duration: isTop && isDragging ? Duration.zero : const Duration(milliseconds: 300),
          top: yOffset,
          child: Transform.translate(
            offset: isTop ? offset : Offset.zero,
            child: Transform.rotate(
              angle: angle * (math.pi / 180),
              child: Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onPanStart: isTop ? _onPanStart : null,
                  onPanUpdate: isTop ? _onPanUpdate : null,
                  onPanEnd: isTop ? _onPanEnd : null,
                  child: Container(
                    width: cardWidth,
                    height: fixedCardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isTop ? 0.2 : 0.1),
                          blurRadius: isTop ? 20 : 15,
                          offset: Offset(0, isTop ? 10 : 5),
                          spreadRadius: isTop ? 1 : 0,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: SizedBox(
                                height: fixedCardHeight * 0.3,
                                width: double.infinity,
                                child: card['resim'] != null && card['resimTuru'] != null
                                    ? Image.memory(
                                        base64Decode(card['resim']),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return _buildGradientArea(fixedCardHeight * 0.3, konu: card['konu']);
                                        },
                                      )
                                    : _buildGradientArea(fixedCardHeight * 0.3, konu: card['konu']),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            card['konu'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          card['baslik'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                      child: Text(
                                        card['aciklama'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          height: 1.6,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // Kaydet butonu
                        if (isTop)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => _toggleSaveCard(cardId),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _savedCardIds.contains(cardId)
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradientArea(double height, {required String konu}) {
    final colors = gradientRenkler[_getColorIndex(_currentIndex)];
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.thumb_up_rounded,
            color: colors[0],
            size: 32,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.6;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
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
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.95),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.konuBaslik,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const KaydedilenKartlarPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kaydedilenler',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // İlerleme Göstergesi
          if (!_isLoading && _cards.isNotEmpty)
            Positioned(
              top: statusBarHeight + 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${_cards.length}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _cards.length,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_cards.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bu konuda henüz kart bulunmuyor.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            // Kartlar
            Positioned.fill(
              top: statusBarHeight + 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(_cards.length, (index) {
                    if (index >= _currentIndex && index < _currentIndex + 5) {
                      return _buildCard(
                        card: _cards[index],
                        cardHeight: cardHeight,
                        isTop: index == _currentIndex,
                        position: index == _currentIndex ? _position : null,
                        scale: 1 - ((index - _currentIndex) * 0.05),
                        angle: index == _currentIndex ? _angle : 0,
                        yOffset: (index - _currentIndex) * 12.0,
                        isDragging: _isDragging,
                      );
                    }
                    return const SizedBox.shrink();
                  }).reversed.toList(),
                  
                  // Kontrol butonları
                  if (!_isLoading && _cards.isNotEmpty)
                    Positioned(
                      bottom: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentIndex > 0)
                            GestureDetector(
                              onTap: _goToPreviousCard,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),
                          const SizedBox(width: 24),
                          if (_currentIndex < _cards.length - 1)
                            GestureDetector(
                              onTap: _goToNextCard,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  
                  // Tutorial overlay
                  if (_showTutorial && !_isLoading && _cards.isNotEmpty)
                    Positioned(
                      bottom: 40,
                      child: Column(
                        children: [
                          SlideTransition(
                            position: _tutorialAnimation,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: AppTheme.primaryColor.withOpacity(0.7),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppTheme.primaryColor.withOpacity(0.7),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Kartları sağa veya sola kaydırın',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 