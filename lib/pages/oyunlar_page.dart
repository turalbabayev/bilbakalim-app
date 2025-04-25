import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'dart:ui';
import 'package:bilbakalim/pages/games/tic_tac_toe_page.dart';
import 'package:bilbakalim/pages/games/yuzde_hesaplama_page.dart';
import 'package:bilbakalim/pages/games/hizli_matematik_page.dart';
import 'package:bilbakalim/pages/games/adam_asmaca_page.dart';
import 'package:bilbakalim/pages/games/kelime_bulmaca_page.dart';
import 'package:bilbakalim/pages/games/eslestirme_page.dart';

class OyunlarPage extends StatelessWidget {
  const OyunlarPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> oyunlar = [
      {
        'baslik': '100\'de Kaç',
        'aciklama': 'Yüzdelik hesaplama becerilerini test et',
        'icon': Icons.percent_rounded,
        'renk1': const Color(0xFF4CAF50),
        'renk2': const Color(0xFF2E7D32),
        'yakinda': false,
        'resim': 'assets/dersResimleri/100_kac.png',
      },
      {
        'baslik': 'Adam Asmaca',
        'aciklama': 'Kelimeleri tahmin et ve puanları topla',
        'icon': Icons.gesture_rounded,
        'renk1': const Color(0xFF2196F3),
        'renk2': const Color(0xFF1565C0),
        'yakinda': false,
        'resim': 'assets/dersResimleri/hamak.png',
      },
      {
        'baslik': 'Eşleştir',
        'aciklama': 'Kavramları doğru eşleştirmeye çalış',
        'icon': Icons.compare_arrows_rounded,
        'renk1': const Color(0xFFFFC107),
        'renk2': const Color(0xFFFFA000),
        'yakinda': false,
        'resim': 'assets/dersResimleri/eslestir.png',
      },
      {
        'baslik': 'Hızlı Matematik',
        'aciklama': '60 saniyede kaç soru çözebilirsin?',
        'icon': Icons.calculate_rounded,
        'renk1': const Color(0xFF9C27B0),
        'renk2': const Color(0xFF6A1B9A),
        'yakinda': false,
        'resim': 'assets/dersResimleri/hizli_mat.png',
      },
      {
        'baslik': 'Kelime Bulmaca',
        'aciklama': 'Karışık harflerden kelimeler bul',
        'icon': Icons.text_fields_rounded,
        'renk1': const Color(0xFFE91E63),
        'renk2': const Color(0xFFC2185B),
        'yakinda': false,
        'resim': 'assets/dersResimleri/bul_bakalim.png',
      },
      {
        'baslik': 'Tic Tac Toe',
        'aciklama': 'Arkadaşınla XOX oyna',
        'icon': Icons.grid_3x3_rounded,
        'renk1': const Color(0xFF3F51B5),
        'renk2': const Color(0xFF283593),
        'yakinda': false,
        'resim': 'assets/dersResimleri/xox_giris.png',
      },
    ];

    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan
          Positioned.fill(
            child: Container(
              color: const Color(0xFFF8F9FA),
            ),
          ),
          
          // Dekoratif şekiller
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
                    AppTheme.primaryColor.withOpacity(0.08),
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
                    AppTheme.primaryColor.withOpacity(0.08),
                    AppTheme.primaryColor.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // Oyunlar Listesi
          Positioned.fill(
            top: statusBarHeight + 80,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: oyunlar.length,
              itemBuilder: (context, index) {
                final oyun = oyunlar[index];
                return Container(
                  height: oyun['baslik'] == 'Eşleştir' 
                      ? 200 
                      : oyun['baslik'] == 'Adam Asmaca'
                          ? 220
                          : oyun['baslik'] == 'Tic Tac Toe'
                              ? 200
                              : 180,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (oyun['baslik'] == 'Tic Tac Toe') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TicTacToePage(),
                            ),
                          );
                        } else if (oyun['baslik'] == '100\'de Kaç') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const YuzdeHesaplamaPage(),
                            ),
                          );
                        } else if (oyun['baslik'] == 'Hızlı Matematik') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HizliMatematikPage(),
                            ),
                          );
                        } else if (oyun['baslik'] == 'Adam Asmaca') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdamAsmacaPage(),
                            ),
                          );
                        } else if (oyun['baslik'] == 'Kelime Bulmaca') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KelimeBulmacaPage(),
                            ),
                          );
                        } else if (oyun['baslik'] == 'Eşleştir') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EslestirmePage(),
                            ),
                          );
                        } else if (oyun['yakinda']) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bu oyun yakında eklenecek!',
                                  style: GoogleFonts.poppins(),
                                ),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(20),
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              oyun['renk1'],
                              oyun['renk2'],
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: oyun['renk1'].withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            if (oyun['resim'] != null) ...[
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    oyun['resim'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ] else ...[
                              // İkon (Sağ alt köşede büyük ve soluk)
                              Positioned(
                                right: -20,
                                bottom: -20,
                                child: Icon(
                                  oyun['icon'],
                                  size: 120,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              // İçerik
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          oyun['icon'],
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          oyun['baslik'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (oyun['yakinda']) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Yakında',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      oyun['aciklama'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                oyun['yakinda'] ? 'Yakında' : 'Oyna',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    top: statusBarHeight + 12,
                    bottom: 16,
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
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.backgroundColorFistik.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Oyunlar',
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
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.sports_esports_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 