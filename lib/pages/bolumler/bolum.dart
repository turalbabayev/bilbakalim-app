import 'package:bilbakalim/pages/bolumler/graphics.dart';
import 'package:bilbakalim/pages/bolumler/test_screen/question_screen.dart';
import 'package:bilbakalim/pages/bolumler/alt_konu.dart';
import 'package:bilbakalim/services/fetch_subtitles.dart';
import 'package:bilbakalim/components/game_background.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BolumPage extends StatelessWidget {
  final String appBarTitle;
  final int bolumIndex;
  const BolumPage({
    super.key,
    required this.appBarTitle,
    required this.bolumIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GameBackground(
        primaryColor: const Color(0xFF6B4EFF),
        secondaryColor: const Color(0xFF8A70FF),
        accentColor: const Color(0xFFB39DFF),
        child: SafeArea(
          child: Column(
            children: [
              // Modern AppBar
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B4EFF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Color(0xFF6B4EFF),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      appBarTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),

              // Alt Bölümler Listesi
              Expanded(
                child: FutureBuilder(
                  future: fetch_subtitles(bolumIndex),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: const Color(0xFF6B4EFF),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Alt Bölümler Yükleniyor...',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFF1A1A2E).withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Hata: ${snapshot.error}',
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data.value == null) {
                      return Center(
                        child: Text(
                          'Veri bulunamadı.',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1A1A2E).withOpacity(0.5),
                          ),
                        ),
                      );
                    }

                    Map<dynamic, dynamic> map = snapshot.data.value as Map<dynamic, dynamic>;
                    List<Map<String, dynamic>> altBolumler = [];

                    map.forEach((key, value) {
                      if (value != null && value is Map) {
                        if (value["baslik"] != null) {
                          altBolumler.add({
                            "key": key,
                            "baslik": value["baslik"].toString(),
                            "altkonular": value["altkonular"],
                          });
                        }
                      }
                    });

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alt Bölümler',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: altBolumler.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.9,
                            ),
                            itemBuilder: (context, index) {
                              final bolum = altBolumler[index];
                              final title = bolum["baslik"] as String;
                              final altKonular = bolum["altkonular"] as Map<dynamic, dynamic>?;

                              return _buildSubjectCard(
                                title: title,
                                onTap: () {
                                  if (altKonular != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AltKonuPage(
                                          altBolumIndex: bolum["key"].toString(),
                                          bolumIndex: bolumIndex.toString(),
                                          altDallar: altKonular,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => QuestionPage(
                                          altKonuIndex: bolum["key"].toString(),
                                          bolumIndex: bolumIndex.toString(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF7F5FF),
              const Color(0xFFF0ECFF),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Alt Bölüm İkon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EFF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                title[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B4EFF),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Alt Bölüm Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            // Başla Butonu
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF6B4EFF),
                    const Color(0xFF8B69F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4EFF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Başla',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
