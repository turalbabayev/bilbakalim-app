import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:bilbakalim/pages/soru_carki_page.dart';
import 'package:bilbakalim/pages/deneme_sinavlari_page.dart';
import 'package:bilbakalim/pages/test_olustur_page.dart';

class SorularPage extends StatelessWidget {
  const SorularPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Stack(
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
        
        // İçerik
        Positioned.fill(
          top: statusBarHeight + 56,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 32, 20, 16 + bottomPadding),
            child: Column(
              children: [
                // Konu Seç-Test Oluştur
                _buildModernCard(
                  title: 'Konu Seç-Test\nOluştur',
                  description: 'İstediğin konulardan test oluştur ve çözmeye başla!',
                  icon: Icons.assignment_outlined,
                  renk1: const Color(0xFF7FE3F0),
                  renk2: const Color(0xFF4EA8DE),
                  buttonText: 'Başla',
                  resim: 'assets/dersResimleri/konu_sec_test.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TestOlusturPage(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Deneme Sınavları
                _buildModernCard(
                  title: 'Deneme\nSınavları',
                  description: 'Konulara göre hazırlanmış deneme sınavlarını çöz',
                  icon: Icons.quiz_rounded,
                  renk1: const Color(0xFF686EDD),
                  renk2: const Color(0xFF8B91FF),
                  buttonText: 'Sınavları Gör',
                  resim: 'assets/dersResimleri/deneme.png',
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Column(
                          children: [
                            Icon(
                              Icons.construction_rounded,
                              size: 48,
                              color: const Color(0xFFFF9800),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Çok Yakında!',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        content: Text(
                          'Deneme sınavları özelliği çok yakında eklenecektir. Takipte kalın!',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppTheme.textColor.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        actions: [
                          Container(
                            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Tamam',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Soru Çarkı
                _buildModernCard(
                  title: 'Soru Çarkı',
                  description: 'Rastgele sorular çözerek kendini test et!',
                  icon: Icons.casino_rounded,
                  renk1: const Color(0xFF9C27B0),
                  renk2: const Color(0xFFE040FB),
                  buttonText: 'Çarkı Çevir',
                  resim: 'assets/dersResimleri/soru_carki2.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SoruCarkiPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
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
                      'Sorular',
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
                        Icons.search_rounded,
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
    );
  }

  Widget _buildModernCard({
    required String title,
    required String description,
    required IconData icon,
    required Color renk1,
    required Color renk2,
    required String buttonText,
    required VoidCallback onTap,
    String? resim,
  }) {
    return Container(
      height: 160,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: resim == null ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [renk1, renk2],
              ) : null,
              image: resim != null ? DecorationImage(
                image: AssetImage(resim),
                fit: BoxFit.cover,
                alignment: resim.contains('deneme_sinavlari') ? const Alignment(0, -0.7) : Alignment.center,
              ) : null,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: renk1.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: resim == null ? Stack(
              children: [
                // Büyük Arkaplan İkonu
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Icon(
                    icon,
                    size: 120,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                // İçerik
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              buttonText,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ) : null,
          ),
        ),
      ),
    );
  }
} 