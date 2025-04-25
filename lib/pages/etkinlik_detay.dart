import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class EtkinlikDetay extends StatefulWidget {
  final Map<String, dynamic> etkinlik;

  const EtkinlikDetay({super.key, required this.etkinlik});

  @override
  State<EtkinlikDetay> createState() => _EtkinlikDetayState();
}

class _EtkinlikDetayState extends State<EtkinlikDetay> {
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final String etkinlikAdi = widget.etkinlik["baslik"] ?? "Etkinlik";
    final String etkinlikAciklamasi = widget.etkinlik["uzunAciklama"] ?? "Bu etkinlik hakkında detaylı bilgi bulunmamaktadır.";
    final String etkinlikFiyati = widget.etkinlik["ucret"] ?? "0";
    final String etkinlikTarihi = _formatDateFromFirebase(widget.etkinlik["tarih"]);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFFF3F0FF),
              const Color(0xFFE8E3FF),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // App Bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF6B4EFF),
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Etkinlik Detayı',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Resim
                    if (widget.etkinlik["resim"] != null && widget.etkinlik["resim"].toString().isNotEmpty)
                      Container(
                        height: 220,
                        width: double.infinity,
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            base64Decode(widget.etkinlik["resim"].toString()),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6B4EFF),
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.event,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Etkinlik Tarihi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B4EFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF6B4EFF),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                etkinlikTarihi,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6B4EFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Etkinlik başlığı
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Text(
                        etkinlikAdi,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                    ),
                    
                    // Ücret kartı
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF8E2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFFAB40).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAB40).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.payments,
                              color: Color(0xFFFFAB40),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Etkinlik Ücreti',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1A1A2E).withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${etkinlikFiyati} ₺',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFFAB40),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isUcretli(etkinlikFiyati) 
                                  ? const Color(0xFFFFAB40) 
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              _isUcretli(etkinlikFiyati) ? 'Ücretli' : 'Ücretsiz',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Özet bilgiler
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          _buildInfoItem(Icons.people, 'Katılımcı', '15+'),
                          const SizedBox(width: 16),
                          _buildInfoItem(Icons.access_time, 'Süre', '2 Saat'),
                          const SizedBox(width: 16),
                          _buildInfoItem(Icons.location_on, 'Konum', 'Online'),
                        ],
                      ),
                    ),
                    
                    // Detay başlık
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Etkinlik Hakkında',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    
                    // Uzun açıklama
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Text(
                        etkinlikAciklamasi,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          height: 1.7,
                          color: const Color(0xFF1A1A2E).withOpacity(0.8),
                        ),
                      ),
                    ),
                    
                    // Özellikler
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F0FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Etkinlik Özellikleri',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureItem(Icons.check_circle_outline, 'Sertifika verilmektedir'),
                          _buildFeatureItem(Icons.devices, 'Tüm cihazlarla erişim sağlanabilir'),
                          _buildFeatureItem(Icons.today, 'Canlı oturum yapılacaktır'),
                          _buildFeatureItem(Icons.question_answer, 'Soru-cevap oturumu içerir'),
                        ],
                      ),
                    ),
                    
                    // Kayıt ol butonu
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: null, // Deaktif buton
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B4EFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Etkinliğe Kayıt Ol',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B4EFF),
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B4EFF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1A1A2E).withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Firebase tarih verisini formatla
  String _formatDateFromFirebase(String? dateString) {
    if (dateString == null) return "Tarih belirtilmemiş";
    
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }
  
  // Etkinlik ücretli mi kontrolü
  bool _isUcretli(dynamic ucret) {
    if (ucret == null) return false;
    
    try {
      // Önce String'e çevir
      String ucretStr = ucret.toString().trim();
      
      // Ondalık ayırıcı olarak virgül veya nokta kullanılmış olabilir
      // Nokta ile virgülü standartlaştır (nokta yap)
      ucretStr = ucretStr.replaceAll(',', '.');
      
      // Double olarak parse et
      double ucretDouble = double.parse(ucretStr);
      return ucretDouble > 0;
    } catch (e) {
      print("Ücret dönüştürme hatası: $e");
      return false; // Hata durumunda ücretsiz olarak işaretle
    }
  }
} 