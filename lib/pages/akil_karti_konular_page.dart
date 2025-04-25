import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:bilbakalim/pages/akil_kartlari_page.dart';
import 'package:google_fonts/google_fonts.dart';

class AkilKartiKonularPage extends StatelessWidget {
  final String? initialDocId;
  
  const AkilKartiKonularPage({
    this.initialDocId,
    Key? key
  }) : super(key: key);

  // Konu resimleri için map
  final Map<String, String> konuResimleri = const {
    'onemli-terimler': 'assets/dersResimleri/onemli_terimler.png',
    'bankacilik': 'assets/dersResimleri/bankacilik.png',
    'cografya': 'assets/dersResimleri/cografya.png',
    'tarih': 'assets/dersResimleri/tarih.png',
    'ekonomi': 'assets/dersResimleri/ekonomi.png',
    'genel_kultur': 'assets/dersResimleri/genel_kultur.png',
    'hukuk': 'assets/dersResimleri/hukuk.png',
    'katilim-bankaciligi': 'assets/dersResimleri/katilim.png',
    'genel-kultur': 'assets/dersResimleri/genel_kultur.png',
    'halkbank': "assets/dersResimleri/mavi_banka.png",
    'ziraat' : "assets/dersResimleri/kirmizi_banka.png",
    'krediler' : "assets/dersResimleri/krediler.png",
    'matematik' : "assets/dersResimleri/matematik.png",
    'muhasebe' : "assets/dersResimleri/muhasebe.png",
    'turkce' : "assets/dersResimleri/turkce.png",
    
    // Diğer ID'ler buraya eklenecek
  };

  // İstenen sıralama
  final List<String> desiredOrder = const [
    'ziraat',
    'halkbank',
    'bankacilik',
    'krediler',
    'muhasebe',
    'hukuk',
    // Diğer ID'ler buraya eklenecek
  ];

  // Resim getirme fonksiyonu
  String? _getKonuResim(String konuId) {
    return konuResimleri[konuId];
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Eğer initialDocId varsa, direkt olarak ilgili akıl kartına yönlendir
    if (initialDocId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseFirestore.instance
            .collection('miniCards-konular')
            .doc(initialDocId)
            .get()
            .then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AkilKartlariPage(
                  konuId: doc.id,
                  konuBaslik: data['baslik'] as String,
                ),
              ),
            );
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // İçerik
          Positioned.fill(
            top: statusBarHeight + 60,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('miniCards-konular')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Bir hata oluştu: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final konular = snapshot.data!.docs;
                
                // Konuları istenen sıraya göre düzenle
                final sortedKonular = List<QueryDocumentSnapshot>.from(konular);
                sortedKonular.sort((a, b) {
                  final indexA = desiredOrder.indexOf(a.id);
                  final indexB = desiredOrder.indexOf(b.id);
                  
                  // Eğer her iki ID de sıralama listesinde varsa, indexlerine göre sırala
                  if (indexA != -1 && indexB != -1) {
                    return indexA.compareTo(indexB);
                  }
                  // Eğer sadece bir ID sıralama listesinde varsa, onu öne al
                  if (indexA != -1) return -1;
                  if (indexB != -1) return 1;
                  // Her iki ID de sıralama listesinde yoksa, mevcut sırayı koru
                  return 0;
                });

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: sortedKonular.length,
                  itemBuilder: (context, index) {
                    final konu = sortedKonular[index].data() as Map<String, dynamic>;
                    final konuId = sortedKonular[index].id;
                    final baslik = konu['baslik'] as String;
                    final resimPath = _getKonuResim(konuId);

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AkilKartlariPage(
                              konuId: konuId,
                              konuBaslik: baslik,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          image: resimPath != null ? DecorationImage(
                            image: AssetImage(resimPath),
                            fit: BoxFit.cover,
                          ) : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.library_books_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  baslik,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Akıl Kartları',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
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
            ),
          ),
        ],
      ),
    );
  }
} 