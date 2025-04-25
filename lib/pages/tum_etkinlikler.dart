import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:bilbakalim/pages/etkinlik_detay.dart';

class TumEtkinliklerPage extends StatelessWidget {
  TumEtkinliklerPage({Key? key}) : super(key: key);

  final DatabaseReference _ref = FirebaseDatabase.instance.ref();

  Future<DataSnapshot> fetchDuyurular() {
    return _ref.child("duyurular").get();
  }

  @override
  Widget build(BuildContext context) {
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6B4EFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.event,
                              color: Color(0xFF6B4EFF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tüm Etkinlikler',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // İçerik
            Expanded(
              child: FutureBuilder(
                future: fetchDuyurular(),
                builder: (context, AsyncSnapshot<DataSnapshot> snapshot) {
                  if (!snapshot.hasData || snapshot.data?.value == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6B4EFF),
                        strokeWidth: 3,
                      ),
                    );
                  }

                  Map<dynamic, dynamic> duyurular = snapshot.data!.value as Map<dynamic, dynamic>;
                  List<Map<String, dynamic>> etkinlikler = [];
                  
                  duyurular.forEach((key, value) {
                    if (value != null && value is Map && value["aktif"] == true && value["tip"] == "Etkinlik") {
                      Map<String, dynamic> etkinlik = {
                        "id": key,
                        "tip": "Etkinlik",
                        "baslik": value["baslik"] ?? "Etkinlik",
                        "kisaAciklama": value["kisaAciklama"] ?? "",
                        "uzunAciklama": value["uzunAciklama"] ?? "",
                        "ucret": value["ucret"] ?? "0",
                        "tarih": value["tarih"] ?? DateTime.now().toString(),
                        "resim": value["resim"] ?? "",
                        "resimTuru": value["resimTuru"] ?? "image/png",
                        "odemeSonrasiIcerik": value["odemeSonrasiIcerik"] ?? "",
                      };
                      etkinlikler.add(etkinlik);
                    }
                  });
                  
                  if (etkinlikler.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            color: const Color(0xFF6B4EFF).withOpacity(0.5),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aktif etkinlik bulunmuyor',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF1A1A2E).withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Etkinlikleri tarihe göre sırala
                  etkinlikler.sort((a, b) {
                    try {
                      DateTime dateA = DateTime.parse(a["tarih"] as String);
                      DateTime dateB = DateTime.parse(b["tarih"] as String);
                      return dateA.compareTo(dateB);
                    } catch (e) {
                      return 0;
                    }
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: etkinlikler.length,
                    itemBuilder: (context, index) {
                      final etkinlik = etkinlikler[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EtkinlikDetay(etkinlik: etkinlik),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Etkinlik resmi
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: Image.memory(
                                  base64Decode(etkinlik["resim"].toString()),
                                  width: 100,
                                  height: 140,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFF6B4EFF),
                                            const Color(0xFF8B69F6),
                                          ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.event,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              
                              // Etkinlik bilgileri
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Ücret etiketi
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Tarih
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6B4EFF).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_rounded,
                                                  color: const Color(0xFF6B4EFF),
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDateFromFirebase(etkinlik["tarih"]),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: const Color(0xFF6B4EFF),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Ücret
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _isUcretli(etkinlik["ucret"])
                                                ? const Color(0xFFFF8F00).withOpacity(0.85)
                                                : const Color(0xFF4CAF50).withOpacity(0.85),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _isUcretli(etkinlik["ucret"])
                                                    ? Icons.paid
                                                    : Icons.card_giftcard,
                                                  color: Colors.white,
                                                  size: 10,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _isUcretli(etkinlik["ucret"])
                                                    ? "${etkinlik["ucret"]} ₺"
                                                    : "Ücretsiz",
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      // Başlık
                                      Text(
                                        etkinlik["baslik"] ?? "Etkinlik",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      
                                      // Kısa açıklama
                                      Text(
                                        etkinlik["kisaAciklama"] ?? "",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: const Color(0xFF1A1A2E).withOpacity(0.7),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      
                                      // Detay butonu
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              const Color(0xFF6B4EFF),
                                              const Color(0xFF8B69F6),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.visibility,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Detayları Görüntüle',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
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
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Firebase tarih verisini formatla
  String _formatDateFromFirebase(dynamic dateString) {
    if (dateString == null) return "Tarih belirtilmemiş";
    
    try {
      DateTime date = DateTime.parse(dateString.toString());
      return "${date.day}.${date.month}.${date.year}";
    } catch (e) {
      return dateString.toString();
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