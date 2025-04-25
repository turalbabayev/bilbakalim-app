import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class KaydedilenKartlarPage extends StatefulWidget {
  const KaydedilenKartlarPage({Key? key}) : super(key: key);

  @override
  State<KaydedilenKartlarPage> createState() => _KaydedilenKartlarPageState();
}

class _KaydedilenKartlarPageState extends State<KaydedilenKartlarPage> {
  List<Map<String, dynamic>> _savedCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  Future<void> _loadSavedCards() async {
    try {
      final userId = 'CURRENT_USER_ID'; // Kullanıcı ID'sini buraya ekleyin
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .orderBy('savedAt', descending: true)
          .get();

      setState(() {
        _savedCards = snapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Kaydedilen kartlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeCard(String cardId) async {
    try {
      final userId = 'CURRENT_USER_ID'; // Kullanıcı ID'sini buraya ekleyin
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('saved_cards')
          .doc(cardId)
          .delete();

      setState(() {
        _savedCards.removeWhere((card) => card['id'] == cardId);
      });

      // SharedPreferences'dan da kaldır
      // final prefs = await SharedPreferences.getInstance();
      // final savedCards = prefs.getStringList('saved_cards') ?? [];
      // savedCards.remove(cardId);
      // await prefs.setStringList('saved_cards', savedCards);
    } catch (e) {
      debugPrint('Kart silinirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                      'Kaydedilen Kartlar',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kartlar Listesi
          Positioned.fill(
            top: statusBarHeight + 100,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _savedCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border_rounded,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz kart kaydetmediniz',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: _savedCards.length,
                        itemBuilder: (context, index) {
                          final card = _savedCards[index];
                          return Dismissible(
                            key: Key(card['id']),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) {
                              _removeCard(card['id']);
                            },
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                    child: SizedBox(
                                      height: 120,
                                      width: double.infinity,
                                      child: card['resim'] != null &&
                                              card['resimTuru'] != null
                                          ? Image.memory(
                                              base64Decode(card['resim']),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return _buildGradientArea(
                                                  120,
                                                  konuBaslik: card['konuBaslik'],
                                                  index: index,
                                                );
                                              },
                                            )
                                          : _buildGradientArea(
                                              120,
                                              konuBaslik: card['konuBaslik'],
                                              index: index,
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            card['konuBaslik'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          card['baslik'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          card['aciklama'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                            height: 1.5,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

  Widget _buildGradientArea(double height,
      {required String konuBaslik, required int index}) {
    final colors = [
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

    final selectedColors = colors[index % colors.length];

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selectedColors,
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
                color: selectedColors[0].withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            color: selectedColors[0],
            size: 32,
          ),
        ),
      ),
    );
  }
} 