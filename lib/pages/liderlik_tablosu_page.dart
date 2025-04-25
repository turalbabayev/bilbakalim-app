import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiderlikTablosuPage extends StatefulWidget {
  const LiderlikTablosuPage({Key? key}) : super(key: key);

  @override
  State<LiderlikTablosuPage> createState() => _LiderlikTablosuPageState();
}

class _LiderlikTablosuPageState extends State<LiderlikTablosuPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _kullanicilar = [];

  @override
  void initState() {
    super.initState();
    _kullanicilariGetir();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _kullanicilariGetir() async {
    try {
      // Firestore referansı
      final firestore = FirebaseFirestore.instance;
      
      // Tüm kullanıcıları al
      final usersSnapshot = await firestore.collection('users').get();

      // Kullanıcı verilerini dönüştür ve sırala
      final List<Map<String, dynamic>> kullanicilar = [];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final characterData = data['character'] ?? {};
        final name = data['name'] ?? '';
        final surname = data['surname'] ?? '';
        final fullName = '$name $surname'.trim();
        final score = data['score'] ?? 0;
        
        kullanicilar.add({
          'id': doc.id,
          'ad': fullName.isEmpty ? 'İsimsiz Kullanıcı' : fullName,
          'puan': score,
          'seviye': data['level'] ?? 1,
          'avatar': characterData['image'] ?? 'assets/animals/aslan.png',
        });
      }

      // Puana göre sırala
      kullanicilar.sort((a, b) {
        final puanA = a['puan'] as int;
        final puanB = b['puan'] as int;
        return puanB.compareTo(puanA);
      });

      // Sıra numarası ekle
      for (int i = 0; i < kullanicilar.length; i++) {
        kullanicilar[i]['sira'] = i + 1;
      }

      setState(() {
        _kullanicilar = kullanicilar;
        _isLoading = false;
      });
    } catch (e) {
      print('Hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Arkaplan şekilleri
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.primaryColor.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF686EDD).withOpacity(0.2),
                    const Color(0xFF686EDD).withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          
          // Ana içerik
          Column(
            children: [
              // Header
              _buildHeader(statusBarHeight),
              
              // Liste
              Expanded(
                child: _buildGenelSiralama(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double statusBarHeight) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: statusBarHeight + 16,
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
                AppTheme.primaryColor.withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Üst kısım - Geri butonu ve başlık
              Row(
                children: [
                  // Geri butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Başlık
                  Text(
                    'Liderlik Tablosu',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_kullanicilar.length >= 3) ...[
                const SizedBox(height: 20),
                // İlk 3 kullanıcı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 2. sıra
                    _buildTopThreeItem(_kullanicilar[1], 2),
                    // 1. sıra
                    _buildTopThreeItem(_kullanicilar[0], 1),
                    // 3. sıra
                    _buildTopThreeItem(_kullanicilar[2], 3),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopThreeItem(Map<String, dynamic> kullanici, int sira) {
    final double size = sira == 1 ? 80 : 65;
    final double fontSize = sira == 1 ? 16 : 14;
    final double maxWidth = sira == 1 ? 120 : 100;
    
    return SizedBox(
      width: maxWidth,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.1),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    kullanici['avatar'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Sıralama rozeti
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _getSiraRenk(sira),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '$sira',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kullanici['ad'],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${kullanici['puan']} XP',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenelSiralama() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_kullanicilar.isEmpty) {
      return Center(
        child: Text(
          'Henüz kullanıcı bulunmuyor',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _kullanicilariGetir,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: _kullanicilar.length,
        itemBuilder: (context, index) {
          final kullanici = _kullanicilar[index];
          return _buildSiralamaItem(kullanici);
        },
      ),
    );
  }

  Widget _buildSiralamaItem(Map<String, dynamic> kullanici) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Kullanıcı profiline git
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Sıra numarası
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _getSiraRenk(kullanici['sira']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${kullanici['sira']}',
                      style: GoogleFonts.poppins(
                        color: _getSiraRenk(kullanici['sira']),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      kullanici['avatar'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Kullanıcı bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kullanici['ad'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Seviye ${kullanici['seviye']}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Puan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${kullanici['puan']} XP',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSiraRenk(int sira) {
    switch (sira) {
      case 1:
        return const Color(0xFFFFD700); // Altın
      case 2:
        return const Color(0xFFC0C0C0); // Gümüş
      case 3:
        return const Color(0xFFCD7F32); // Bronz
      default:
        return Colors.grey;
    }
  }
} 