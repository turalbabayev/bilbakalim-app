import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/pages/guncel_bilgiler_page.dart';
import 'package:bilbakalim/pages/akil_kartlari_page.dart';
import 'package:bilbakalim/pages/not_defteri_page.dart';
import 'package:bilbakalim/services/fetch_titles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bilbakalim/pages/alt_konular_page.dart';
import 'package:bilbakalim/pages/katilim_bankaciligi_page.dart';
import 'package:bilbakalim/pages/akil_karti_konular_page.dart';

class DersModel {
  final String id;
  final String baslik;

  DersModel({
    required this.id,
    required this.baslik,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baslik': baslik,
      'icon': Icons.school_outlined,
    };
  }
}

class DersPage extends StatefulWidget {
  final bool firebaseInitialized;
  
  const DersPage({
    required this.firebaseInitialized,
    Key? key
  }) : super(key: key);

  @override
  State<DersPage> createState() => _DersPageState();
}

class _DersPageState extends State<DersPage> {
  Future<Map<String, String>> _getDersler() async {
    final titles = await fetchTitles();
    print("Firebase'den gelen başlıklar:");
    titles.forEach((key, value) {
      print("Key: $key, Value: $value");
    });
    
    // Katılım bankacılığı konularının ID'leri
    final katilimKonulariIds = [
      "-OMxOQiPA8iue7tcF71O",
      "-OMxObWfMWK_gl7F4fYN",
      "-OMwqcmZd1wBykLhWy2X",
      "-OMxKME94u1eKgCtQjsg",
      "-OMxIqn_AbJuMHAXQcMl"
    ];
    
    // İstenen sıralama
    final desiredOrder = [
      "-ONeRGyvr31dGogqlFCg", // Kırmızı Banka
      "-ONQsTIOyKwczkD0qrio", // Mavi Banka
      "-OKAdBq7LH6PXcW457aN", // Bankacılık
      "4",  // Krediler
      "-OKAk2EbpC1xqSwbJbYM", // Muhasebe
      "3",  // Hukuk
      "2",  // Ekonomi
      "6",  // Genel Kültür
    ];
    
    // Yeni bir Map oluştur
    Map<String, String> filteredTitles = {};
    
    // Önce istenen sıralamadaki dersleri ekle
    for (var id in desiredOrder) {
      if (titles.containsKey(id)) {
        filteredTitles[id] = titles[id]!;
      }
    }
    
    // Katılım bankacılığı konularını tek bir başlık altında topla ve diğer dersleri ekle
    bool hasKatilimKonulari = false;
    titles.forEach((key, value) {
      if (katilimKonulariIds.contains(key)) {
        if (!hasKatilimKonulari) {
          filteredTitles["katilim_bankaciligi"] = "Katılım\nBankacılığı";
          hasKatilimKonulari = true;
        }
      } else if (!desiredOrder.contains(key)) {
        // İstenen sıralamada olmayan diğer dersleri en sona ekle
        filteredTitles[key] = value;
      }
    });
    
    print("\nFiltrelenmiş başlıklar:");
    filteredTitles.forEach((key, value) {
      print("Key: $key, Value: $value");
    });
    
    return filteredTitles;
  }

  // Ders resimlerini eşleştiren map
  final Map<String, String> dersResimleri = {
    '-OKAdBq7LH6PXcW457aN': 'assets/dersResimleri/bankacilik.png',
    '-OKAk2EbpC1xqSwbJbYM': 'assets/dersResimleri/muhasebe.png',
    '-OKw6fKcYGunlY_PbCo3': 'assets/dersResimleri/matematik.png',
    '-OMBcE1I9DRj8uvlYSmH': 'assets/dersResimleri/turkce.png',
    '-OMhpwKF1PZ0-QnjyJm8': 'assets/dersResimleri/tarih2.png',
    '-OMlVD6ufbDvCgZhfz8N': 'assets/dersResimleri/cografya.png',
    '2': 'assets/dersResimleri/ekonomi.png',
    '3': 'assets/dersResimleri/hukuk.png',
    '4': 'assets/dersResimleri/krediler.png',
    '6': 'assets/dersResimleri/genel_kultur.png',
    'katilim_bankaciligi': 'assets/dersResimleri/katilim.png',
    '-ONQsTIOyKwczkD0qrio': 'assets/dersResimleri/mavi_banka.png',
    '-ONeRGyvr31dGogqlFCg': 'assets/dersResimleri/kirmizi_banka.png',
    '7': 'assets/dersResimleri/onemli_terimler.png',
  };

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 40 - 24) / 3;
    final itemHeight = itemWidth * 1.4;
    
    return Stack(
      children: [
        // İçerik
        Positioned.fill(
          top: statusBarHeight + 60,
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tüm Dersler',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: itemHeight + 64,
                        child: !widget.firebaseInitialized
                        ? Center(
                            child: Text(
                              'Firebase bağlantısı bekleniyor...',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          )
                        : FutureBuilder<Map<String, String>>(
                            future: _getDersler(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6B4EFF),
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Dersler yüklenirken hata oluştu',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }

                              final titles = snapshot.data ?? {};
                              
                              if (titles.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Henüz ders bulunmuyor',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }

                              final entries = titles.entries.toList();
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: entries.length,
                                itemBuilder: (context, index) {
                                  final entry = entries[index];
                                  return Container(
                                    width: itemWidth,
                                    height: itemHeight + 48,
                                    margin: EdgeInsets.only(
                                      right: index != entries.length - 1 ? 12 : 0,
                                    ),
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (entry.key == 'katilim_bankaciligi') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => const KatilimBankaciligiPage(),
                                                ),
                                              );
                                            } else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => AltKonularPage(
                                                    konuId: entry.key,
                                                    konuBaslik: entry.value,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            height: itemHeight,
                                            decoration: BoxDecoration(
                                              color: _getDersResim(entry.key) == null ? AppTheme.primaryColor : null,
                                              borderRadius: BorderRadius.circular(16),
                                              image: _getDersResim(entry.key) != null
                                                ? DecorationImage(
                                                    image: AssetImage(_getDersResim(entry.key)!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: _getDersResim(entry.key) == null ? Center(
                                              child: Icon(
                                                entry.key == 'katilim_bankaciligi' 
                                                    ? Icons.account_balance_outlined
                                                    : _getDersIcon(entry.value),
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ) : null,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 36,
                                          child: Text(
                                            entry.value,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textColor,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildNotlarGrid(),
                ],
              ),
            ),
          ),
        ),
        
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Dersler',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getDersIcon(String dersAdi) {
    final dersAdiLower = dersAdi.toLowerCase();
    if (dersAdiLower.contains('matematik')) {
      return Icons.calculate_outlined;
    } else if (dersAdiLower.contains('fizik')) {
      return Icons.science_outlined;
    } else if (dersAdiLower.contains('kimya')) {
      return Icons.biotech_outlined;
    } else if (dersAdiLower.contains('biyoloji')) {
      return Icons.spa_outlined;
    } else if (dersAdiLower.contains('türkçe')) {
      return Icons.menu_book_outlined;
    } else if (dersAdiLower.contains('tarih')) {
      return Icons.history_edu_outlined;
    } else if (dersAdiLower.contains('coğrafya')) {
      return Icons.public_outlined;
    }
    return Icons.school_outlined;
  }

  // Not kartları için veriler
  final List<Map<String, dynamic>> notKartlari = [
    {
      'baslik': 'Akıl\nKartları',
      'renk': const Color(0xFFB195E4),
      'icon': Icons.note_outlined,
      'iconRenk': Colors.white,
      'neonRenk': const Color(0xFFB195E4),
      'resim': 'assets/dersResimleri/kartlar_dikey.png',
      'genislik': 1, // 1 = yarım genişlik
    },
    {
      'baslik': 'Güncel\nBilgiler',
      'renk': const Color(0xFF7FE3F0),
      'icon': Icons.description_outlined,
      'iconRenk': Colors.white,
      'neonRenk': const Color(0xFF7FE3F0),
      'resim': 'assets/dersResimleri/guncel_bilgiler.png',
      'genislik': 1, // 1 = yarım genişlik
    },
    {
      'baslik': 'Önemli\nTerimler',
      'renk': const Color(0xFFE3F6F9),
      'icon': Icons.lightbulb_outline,
      'iconRenk': const Color(0xFF1A1F71),
      'neonRenk': const Color(0xFF1A1F71),
      'resim': 'assets/dersResimleri/onemli_terimler.png',
      'genislik': 2, // 2 = tam genişlik
    },
  ];

  Widget _buildNotlarGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 52) / 2; // 20 sol + 20 sağ + 12 orta padding
    final cardHeight = cardWidth * 0.95; // Kare yerine biraz daha kısa bir oran
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notlar',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol sütun (Güncel Bilgiler ve Önemli Bilgiler)
            Expanded(
              child: Column(
                children: [
                  _buildNotCard(notKartlari[1], height: cardHeight), // Güncel Bilgiler
                  const SizedBox(height: 12),
                  _buildNotCard(notKartlari[2], height: cardHeight), // Önemli Bilgiler
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Sağ sütun (Akıl Kartları - uzun kart)
            Expanded(
              child: _buildNotCard(notKartlari[0], height: (cardHeight * 2) + 12), // Akıl Kartları
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotCard(Map<String, dynamic> kart, {required double height}) {
    final isDark = kart['renk'].computeLuminance() < 0.5;
    final bool hasImage = kart['resim'] != null;
    
    return GestureDetector(
      onTap: () {
        if (kart['baslik'].contains('Güncel')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GuncelBilgilerPage(),
            ),
          );
        } else if (kart['baslik'].contains('Akıl')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AkilKartiKonularPage(),
            ),
          );
        } else if (kart['baslik'].contains('Önemli')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AkilKartiKonularPage(
                initialDocId: 'onemli-terimler',
              ),
            ),
          );
        }
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: hasImage ? null : kart['renk'],
          borderRadius: BorderRadius.circular(16),
          image: hasImage ? DecorationImage(
            image: AssetImage(kart['resim']!),
            fit: BoxFit.cover,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: (hasImage ? AppTheme.primaryColor : kart['renk']).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }

  String? _getDersResim(String dersAdi) {
    return dersResimleri[dersAdi];
  }
} 