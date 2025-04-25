import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class GuncelBilgilerPage extends StatefulWidget {
  const GuncelBilgilerPage({super.key});

  @override
  State<GuncelBilgilerPage> createState() => _GuncelBilgilerPageState();
}

class _GuncelBilgilerPageState extends State<GuncelBilgilerPage> {
  final ValueNotifier<Offset> _position = ValueNotifier<Offset>(Offset.zero);
  bool _isDragging = false;
  double _angle = 0;
  int _currentIndex = 0;
  List<Map<String, dynamic>> _cards = [];
  bool _isLoading = true;
  
  // Kullanıcının etkileşimlerini takip etmek için
  Set<String> _likedCards = {};
  Set<String> _unlikedCards = {};
  Set<String> _reportedCards = {};

  final List<List<Color>> gradientRenkler = [
    [const Color(0xFF434CDC), const Color(0xFF686EDD)],
    [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
    [const Color(0xFF4ECDC4), const Color(0xFF6EE7E7)],
    [const Color(0xFFFFBE0B), const Color(0xFFFFD93D)],
    [const Color(0xFF8338EC), const Color(0xFF9D68E7)],
    [const Color(0xFFFF006E), const Color(0xFFFF4D8D)],
    [const Color(0xFF3A86FF), const Color(0xFF5B9FFF)],
    [const Color(0xFF38B000), const Color(0xFF57CC2E)],
    [const Color(0xFFFF477E), const Color(0xFFFF71A2)],
    [const Color(0xFF7209B7), const Color(0xFF9B42D1)],
  ];

  @override
  void initState() {
    super.initState();
    _loadCards();
    _loadUserInteractions();
  }

  Future<void> _loadUserInteractions() async {
    try {
      final userId = 'CURRENT_USER_ID'; // Kullanıcı ID'sini buraya ekleyin
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('interactions')
          .doc('guncelBilgiler')
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
    setState(() {
          _likedCards = Set<String>.from(data['liked'] ?? []);
          _unlikedCards = Set<String>.from(data['unliked'] ?? []);
          _reportedCards = Set<String>.from(data['reported'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Kullanıcı etkileşimleri yüklenirken hata: $e');
    }
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('guncelBilgiler')
          .orderBy('tarih', descending: true)
          .get();

    setState(() {
        _cards = querySnapshot.docs
            .map((doc) {
              final data = doc.data();
              // HTML etiketlerini temizle
              String icerik = data['icerik'] ?? '';
              icerik = icerik.replaceAll(RegExp(r'<[^>]*>'), '');
              
              return {
                ...data,
                'id': doc.id,
                'icerik': icerik,
              };
            })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilgiler yüklenirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _updateCardStatus(String cardId, String field, bool value) async {
    try {
      // Firestore'da ilgili field'ı güncelle (int olarak)
      await FirebaseFirestore.instance
          .collection('guncelBilgiler')
          .doc(cardId)
          .update({field: value ? 1 : 0});

      setState(() {
        final cardIndex = _cards.indexWhere((card) => card['id'] == cardId);
        if (cardIndex != -1) {
          _cards[cardIndex][field] = value ? 1 : 0;
          
          // Eğer beğeni yapılıyorsa, beğenmemeyi kaldır
          if (field == 'liked' && value) {
            _cards[cardIndex]['unliked'] = 0;
            // Firestore'da unliked'ı false yap
            FirebaseFirestore.instance
                .collection('guncelBilgiler')
                .doc(cardId)
                .update({'unliked': 0});
          }
          // Eğer beğenmeme yapılıyorsa, beğeniyi kaldır
          else if (field == 'unliked' && value) {
            _cards[cardIndex]['liked'] = 0;
            // Firestore'da liked'ı false yap
            FirebaseFirestore.instance
                .collection('guncelBilgiler')
                .doc(cardId)
                .update({'liked': 0});
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İşlem gerçekleştirilemedi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.85;
    
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
                  Text(
                    'Güncel Bilgiler',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

          // Kartlar
          Positioned.fill(
            top: statusBarHeight + 140,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _cards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz güncel bilgi bulunmuyor',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          ..._cards.asMap().entries.map((entry) {
                            if (entry.key == _currentIndex) {
                              return ValueListenableBuilder<Offset>(
                                valueListenable: _position,
                                builder: (context, offset, _) {
                                  return AnimatedPositioned(
                                    duration: _isDragging
                                        ? Duration.zero
                                        : const Duration(milliseconds: 300),
                                    left: (screenWidth - cardWidth) / 2 + offset.dx,
                                    top: 0,
                                    child: Transform.rotate(
                                      angle: _angle * math.pi / 180,
                                      child: GestureDetector(
                                        onPanStart: (details) {
                                          setState(() => _isDragging = true);
                                        },
                                        onPanUpdate: (details) {
                                          _position.value += details.delta;
                                          setState(() {
                                            _angle = _position.value.dx / 20;
                                          });
                                        },
                                        onPanEnd: (details) {
                                          final threshold = screenWidth / 3;
                                          if (_position.value.dx.abs() > threshold) {
                                            double direction = _position.value.dx.sign;
                                            setState(() {
                                              if (direction < 0 && _currentIndex < _cards.length - 1) {
                                                _currentIndex++;
                                              } else if (direction > 0 && _currentIndex > 0) {
                                                _currentIndex--;
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
                                        },
                                        child: _buildCard(entry.value, true),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                            return const SizedBox();
                          }).toList(),

                          // Kontrol butonları
                          if (!_isLoading && _cards.isNotEmpty)
                            Positioned(
                              bottom: 40,
                              left: 0,
                              right: 0,
                              child: Column(
                                children: [
                                  // Kaydırma yönlendirmesi
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.arrow_back_ios_rounded,
                                          size: 16,
                                          color: _currentIndex > 0 
                                              ? AppTheme.primaryColor.withOpacity(0.7)
                                              : Colors.grey[300],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Kaydırın',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 16,
                                          color: _currentIndex < _cards.length - 1 
                                              ? AppTheme.primaryColor.withOpacity(0.7)
                                              : Colors.grey[300],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Etkileşim butonları
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildActionButton(
                                          icon: Icons.thumb_up_rounded,
                                          isActive: (_cards[_currentIndex]['liked'] ?? 0) == 1,
                                          onTap: () => _updateCardStatus(
                                            _cards[_currentIndex]['id'],
                                            'liked',
                                            (_cards[_currentIndex]['liked'] ?? 0) == 0,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        _buildActionButton(
                                          icon: Icons.thumb_down_rounded,
                                          isActive: (_cards[_currentIndex]['unliked'] ?? 0) == 1,
                                          onTap: () => _updateCardStatus(
                                            _cards[_currentIndex]['id'],
                                            'unliked',
                                            (_cards[_currentIndex]['unliked'] ?? 0) == 0,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        _buildActionButton(
                                          icon: Icons.flag_rounded,
                                          isActive: (_cards[_currentIndex]['report'] ?? 0) == 1,
                                          onTap: () => _updateCardStatus(
                                            _cards[_currentIndex]['id'],
                                            'report',
                                            (_cards[_currentIndex]['report'] ?? 0) == 0,
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
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> card, bool isActive) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = screenHeight * 0.65;
    final imageHeight = cardHeight * 0.35;

    return Container(
      width: cardWidth,
      height: cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
          // Resim veya Gradient Alanı
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
            child: SizedBox(
              height: imageHeight,
                            width: double.infinity,
              child: card['resim'] != null
                  ? Builder(
                      builder: (context) {
                        try {
                          String base64String = card['resim'].toString();
                          if (base64String.contains(',')) {
                            base64String = base64String.split(',')[1];
                          }
                          return Image.memory(
                            base64Decode(base64String),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildGradientArea(imageHeight),
                          );
                        } catch (e) {
                          return _buildGradientArea(imageHeight);
                        }
                      },
                    )
                  : _buildGradientArea(imageHeight),
            ),
          ),

          // Başlık ve Tarih Alanı
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
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
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(
                      (card['tarih'] as Timestamp).toDate(),
                    ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                                  ),
                                ),
                const SizedBox(height: 16),
                                Text(
                  card['baslik'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

          // İçerik Alanı
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white,
                    Colors.white.withOpacity(0.1),
                  ],
                  stops: const [0.0, 0.85, 0.95, 1.0],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Text(
                  card['icerik'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? AppTheme.primaryColor : Colors.grey[400],
          size: 24,
        ),
      ),
    );
  }

  Widget _buildGradientArea(double height) {
    final colors = gradientRenkler[_currentIndex % gradientRenkler.length];
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
            Icons.article_rounded,
            color: colors[0],
            size: 32,
          ),
        ),
      ),
    );
  }
} 
