import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/pages/alt_konular_page.dart';

class KatilimBankaciligiPage extends StatelessWidget {
  const KatilimBankaciligiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    final List<Map<String, dynamic>> konular = [
      {
        "id": "1",
        "baslik": "KATILIM BANKALARININ FON KULLANDIRMA YÖNTEMLERİ VE ÜRÜNLERİ",
        "icon": Icons.account_balance_outlined,
        "color": const Color(0xFF7FE3F0),
      },
      {
        "id": "2",
        "baslik": "İSLÂMÎ FİNANS VE KATILIM BANKACILIĞI",
        "icon": Icons.currency_exchange,
        "color": const Color(0xFFB195E4),
      },
      {
        "id": "3",
        "baslik": "KATILIM BANKACILIĞI ve TARİHSEL GELİŞİMİ",
        "icon": Icons.history_edu_outlined,
        "color": const Color(0xFF1A1F71),
      },
      {
        "id": "4",
        "baslik": "KATILIM BANKACILIĞI / İSLAM EKONOMİSİ'NİN İLKELERİ ve FAİZ YASAĞI",
        "icon": Icons.gavel_outlined,
        "color": const Color(0xFF7FE3F0),
      },
      {
        "id": "5",
        "baslik": "KATILIM BANKACILIĞI /ULUSLARARASI İSLAMI FINANSAL KURUMLAR",
        "icon": Icons.public_outlined,
        "color": const Color(0xFFB195E4),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // İçerik
          Positioned.fill(
            top: statusBarHeight + 80,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ...konular.map((konu) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AltKonularPage(
                              konuId: konu['id']!,
                              konuBaslik: konu['baslik']!,
                            ),
                          ),
                        );
                      },
                      child: Container(
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
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: (konu['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                konu['icon'] as IconData,
                                color: konu['color'] as Color,
                                size: 28,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      konu['baslik']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textColor,
                                        height: 1.3,
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
                  )).toList(),
                ],
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
                      'Katılım Bankacılığı',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 