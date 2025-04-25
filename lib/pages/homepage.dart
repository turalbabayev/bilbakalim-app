import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Locale verileri için
import 'dart:convert'; // Base64 işlemleri için
import 'dart:typed_data'; // Uint8List için
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bilbakalim/pages/profil_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:bilbakalim/pages/liderlik_tablosu_page.dart';
import 'package:bilbakalim/pages/istatistiklerim_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilbakalim/pages/premium_page.dart';

class HomePage extends StatefulWidget {
  final bool firebaseInitialized;
  
  const HomePage({required this.firebaseInitialized, Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _duyurularStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _etkinliklerStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _informationsStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;
  
  @override
  void initState() {
    super.initState();
    if (widget.firebaseInitialized) {
      _duyurularStream = FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('tarih', descending: true)
          .snapshots();
          
      _informationsStream = FirebaseFirestore.instance
          .collection('informations')
          .orderBy('tarih', descending: true)
          .snapshots();
          
      // Kullanıcı bilgilerini dinle
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint("Kullanıcı ID: ${currentUser.uid}");
        _userStream = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots();
      } else {
        debugPrint("Kullanıcı oturum açmamış!");
      }
    }
        
    
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Column(
      children: [
        // Header - Status bar'ın altından başlayacak
        _buildHeader(context, statusBarHeight),
        
        // İçerik
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/dersResimleri/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Üyelik Butonu
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _userStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final userData = snapshot.data!.data();
                        if (userData != null) {
                          final isPremium = userData['isPremium'] ?? false;
                          
                          if (!isPremium) {
                            return Column(
                              children: [
                                _buildPremiumButton(),
                                const SizedBox(height: 16),
                              ],
                            );
                          }
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  
                  // Duyurular Başlığı
                  _buildSectionTitle('Duyurular', icon: Icons.campaign_rounded),
                  const SizedBox(height: 8),
                  
                  // Duyurular Listesi - Realtime Database'den
                  _buildAnnouncements(),
                  
                  const SizedBox(height: 16),
                  
                  // Etkinlikler Bölümü - StreamBuilder kullanarak etkinlik varsa gösterilecek
                  _buildEventsSection(context),
                  
                  const SizedBox(height: 16),
                  
                  // Leaderboard ve İstatistikler
                  _buildLeaderboardPreview(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.campaign_rounded,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnnouncements() {
    if (!widget.firebaseInitialized) {
      debugPrint("Firebase başlatılmadı!");
      return const Center(
        child: Text('Firebase başlatılamadı'),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _duyurularStream,
      builder: (context, duyurularSnapshot) {
        if (duyurularSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _informationsStream,
          builder: (context, informationsSnapshot) {
            if (duyurularSnapshot.hasError || informationsSnapshot.hasError) {
              debugPrint("Firestore hata detayı: ${duyurularSnapshot.error ?? informationsSnapshot.error}");
              return Center(
                child: Text('Veriler yüklenirken hata: ${duyurularSnapshot.error ?? informationsSnapshot.error}'),
              );
            }

            // Duyuruları işle
            final duyurular = duyurularSnapshot.data?.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'baslik': data['baslik'] ?? 'Başlıksız',
                'aciklama': data['aciklama'] ?? '',
                'resim': data['resim'],
                'aktif': data['aktif'] ?? false,
                'tarih': data['tarih'] is Timestamp 
                    ? data['tarih'].toDate() 
                    : data['tarih'] is String 
                        ? DateTime.parse(data['tarih'])
                        : DateTime.now(),
                'tip': 'duyuru'
              };
            }).where((duyuru) => duyuru['aktif'] == true).toList() ?? [];

            // Bilgilendirmeleri işle
            final bilgilendirmeler = informationsSnapshot.data?.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'baslik': data['baslik'] ?? 'Başlıksız',
                'aciklama': data['kisaAciklama'] ?? '',
                'resim': data['resim'],
                'aktif': data['aktif'] ?? false,
                'tarih': data['tarih'] is Timestamp 
                    ? data['tarih'].toDate() 
                    : data['tarih'] is String 
                        ? DateTime.parse(data['tarih'])
                        : DateTime.now(),
                'tip': 'bilgilendirme'
              };
            }).where((bilgi) => bilgi['aktif'] == true).toList() ?? [];

            // İki listeyi birleştir ve tarihe göre sırala
            final tumIcerikler = [...duyurular, ...bilgilendirmeler];
            tumIcerikler.sort((a, b) => (b['tarih'] as DateTime).compareTo(a['tarih'] as DateTime));

            if (tumIcerikler.isEmpty) {
              return const Center(
                child: Text('Gösterilecek içerik bulunmuyor'),
              );
            }

            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: tumIcerikler.length,
                itemBuilder: (context, index) {
                  final icerik = tumIcerikler[index];
                  final cardColor = icerik['tip'] == 'duyuru' 
                      ? Colors.blue.withOpacity(0.3) 
                      : Colors.purple.withOpacity(0.3);
                  final etiket = icerik['tip'] == 'duyuru' ? 'DUYURU' : 'BİLGİLENDİRME';
                  
                  return _buildAnnouncementCard(
                    baslik: icerik['baslik'].toString(),
                    kisaAciklama: icerik['aciklama'].toString(),
                    resimBase64: icerik['resim'],
                    cardColor: cardColor,
                    etiket: etiket,
                    duyuruTipi: icerik['tip'].toString(),
                    target: null,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  
  // Etkinlikler bölümünü koşullu olarak gösteren widget
  Widget _buildEventsSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _etkinliklerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          debugPrint("Firestore etkinlik hatası: ${snapshot.error}");
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final etkinlikler = snapshot.data!.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();

        // Aktif etkinlikleri filtrele
        final aktifEtkinlikler = etkinlikler.where((etkinlik) {
          return etkinlik['aktif'] == true && etkinlik['tip']?.toLowerCase() == 'etkinlik';
        }).toList();

        if (aktifEtkinlikler.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Etkinlikler', icon: Icons.event_available_rounded),
            const SizedBox(height: 8),
            _buildEventsList(aktifEtkinlikler),
          ],
        );
      },
    );
  }
  
  // Etkinlikler listesi - artık etkinlik listesini parametre olarak alıyor
  Widget _buildEventsList(List<Map<String, dynamic>> events) {
    final List<Color> eventColors = [
      Colors.cyan.shade600,
      Colors.amber.shade600,
      Colors.purple.shade600,
      Colors.teal.shade600,
      Colors.deepOrange.shade600,
      Colors.indigo.shade600,
      Colors.pink.shade600,
      Colors.green.shade600,
    ];

    eventColors.shuffle();
    final limitedList = events.length > 5 ? events.sublist(0, 5) : events;
    
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: limitedList.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16),
        itemBuilder: (context, index) {
          final data = limitedList[index];
          final cardColor = eventColors[index % eventColors.length];
          
          return _buildEventCardForCarousel(
            baslik: data['baslik'] ?? 'Etkinlik',
            aciklama: data['kisaAciklama'] ?? 'İçerik bulunmamaktadır.',
            tarih: data['tarih'] ?? 'Yakında',
            ucret: data['ucret'] != null 
                ? (data['ucret'] is double 
                    ? data['ucret'] 
                    : double.tryParse(data['ucret'].toString()) ?? 0.0) 
                : 0.0,
            odemeSonrasiIcerik: data['odemeSonrasiIcerik'],
            resimUrl: data['resim'] as String?,
            cardColor: cardColor,
          );
        },
      ),
    );
  }
  
  // Örnek etkinlikleri getiren metot - boş liste kontrol edebilmek için ayrı metot
  List<Map<String, dynamic>> _buildSampleEvents() {
    return [
      {
        'baslik': 'Yazılım Workshop',
        'kisaAciklama': 'Profesyonel gelişim için uygulamalı teknik eğitim',
        'tarih': '20 Haziran 2023',
        'tip': 'etkinlik',
        'aktif': true,
        'fiyat': 149.99,
        'resim': null,
        'odemeSonrasiIcerik': 'Workshop slaytları ve kaynak kodlar',
        'renk': Colors.cyan, // Turkuaz
      },
      {
        'baslik': 'Yapay Zeka Semineri',
        'kisaAciklama': 'AI teknolojileri ve gelecekteki etkileri hakkında bilgilendirme',
        'tarih': '15 Temmuz 2023',
        'tip': 'etkinlik',
        'aktif': true,
        'fiyat': 99.90,
        'resim': null,
        'odemeSonrasiIcerik': 'Kayıtlı video ve katılım sertifikası',
        'renk': Colors.amber, // Neon sarı
      },
      {
        'baslik': 'Kitap İmza Günü',
        'kisaAciklama': 'Yeni çıkan yazılım kitabı için imza etkinliği',
        'tarih': '10 Ağustos 2023',
        'tip': 'etkinlik',
        'aktif': true,
        'fiyat': 24.50,
        'resim': null,
        'odemeSonrasiIcerik': null,
        'renk': AppTheme.primaryColor, // Ana tema rengi
      }
    ];
  }
  
  // Örnek etkinlikler göster - Carousel için düzenlenmiş
  Widget _buildSampleEventsCarousel() {
    final events = _buildSampleEvents();
    
    return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                'Yaklaşan Etkinlikler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tüm etkinlikler sayfası açılıyor'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text('Tümü'),
                                  ),
                                ],
                              ),
                            ),
                    SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCardForCarousel(
                baslik: events[index]['baslik'] as String,
                aciklama: events[index]['kisaAciklama'] as String,
                tarih: events[index]['tarih'] as String,
                ucret: events[index]['fiyat'] as double,
                odemeSonrasiIcerik: events[index]['odemeSonrasiIcerik'] as String?,
                resimUrl: events[index]['resim'] as String?,
                cardColor: events[index]['renk'] as Color?,
              );
            },
          ),
        ),
      ],
    );
  }
  
  // Carousel için etkinlik kartı oluştur
  Widget _buildEventCardForCarousel({
    required String baslik,
    required String aciklama,
    required String tarih,
    required double ucret,
    String? odemeSonrasiIcerik,
    String? resimUrl,
    Color? cardColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$baslik etkinliği için detaylar açılıyor'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 260,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF686EDD).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (resimUrl != null)
                        FutureBuilder<Uint8List>(
                          future: _decodeBase64Image(resimUrl),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && 
                                snapshot.hasData && 
                                snapshot.data!.isNotEmpty) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              );
                            } else {
                              return Center(
                                child: Icon(
                                  Icons.event,
                                  size: 36,
                                  color: const Color(0xFF686EDD),
                                ),
                              );
                            }
                          },
                        )
                      else
                        Center(
                          child: Icon(
                            Icons.event,
                            size: 36,
                            color: const Color(0xFF686EDD),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF434CDC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFF6DF90),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${ucret.toStringAsFixed(2)} TL',
                                style: const TextStyle(
                                  color: Color(0xFFF6DF90),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFFF6DF90),
                                      blurRadius: 4,
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
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          baslik,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A2E7B),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aciklama,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.6),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF686EDD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: const Color(0xFF686EDD),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tarih,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF686EDD),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF686EDD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Color(0xFF686EDD),
                              ),
                            ),
                          ],
                        ),
                      ],
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
  
  Widget _buildHeader(BuildContext context, double statusBarHeight) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: statusBarHeight + 8,
            bottom: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF3FF6C),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo ve uygulama adı
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BilBakalım',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF520A8B),
                        ),
                      ),
                      Text(
                        'Bilgi Yarışması',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF520A8B).withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Puan ve profil
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _userStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const SizedBox(
                            width: 50,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF520A8B),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF520A8B),
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    debugPrint("Kullanıcı bilgileri yüklenirken hata: ${snapshot.error}");
                    return const SizedBox.shrink();
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    debugPrint("Kullanıcı verisi bulunamadı!");
                    return const SizedBox.shrink();
                  }

                  final userData = snapshot.data!.data()!;
                  debugPrint("Kullanıcı verisi: $userData");
                  final userScore = userData['score'] ?? 0;
                  final characterData = userData['character'] as Map<String, dynamic>?;
                  final characterImage = characterData?['image'] as String?;
                  debugPrint("Karakter resmi: $characterImage");

                  return Row(
                    children: [
                      // Puan göstergesi
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              userScore.toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF520A8B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Profil butonu
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilPage(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: characterImage != null && characterImage.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    characterImage,
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Firebase'den kullanıcının hayvan profilini aldığımızı simüle eden metod
  String _getUserAnimalProfile() {
    // Normalde burada:
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    //   final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    //   return userData['animalProfile'] ?? 'assets/animals/aslan.png';
    // }
    
    // Örnek olarak farklı hayvanlardan birini gösterelim
    final animalsList = [
      'assets/animals/aslan.png',
      'assets/animals/kartal.png',
      'assets/animals/kedi.png',
      'assets/animals/peri.png',
    ];
    
    // Rastgele seçim yapma mantığı (gerçekte kaydedilen hayvan gösterilecek)
    final randomIndex = DateTime.now().millisecondsSinceEpoch % animalsList.length;
    return animalsList[randomIndex];
  }

  // Kategoriler bölümü
  Widget _buildCategoriesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
              'Kategoriler',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Kategoriler Grid
          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
              childAspectRatio: 1.5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                                            children: [
                // Kategori kartları
                _buildCategoryCard(
                  'Matematik',
                  'assets/images/math_icon.png',
                  Colors.blue.shade500,
                ),
                _buildCategoryCard(
                  'Fizik',
                  'assets/images/physics_icon.png',
                  Colors.red.shade500,
                ),
                _buildCategoryCard(
                  'Kimya',
                  'assets/images/chemistry_icon.png',
                  Colors.purple.shade500,
                ),
                _buildCategoryCard(
                  'Biyoloji',
                  'assets/images/biology_icon.png',
                  Colors.green.shade500,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
  }

  // Kategori kartı
  Widget _buildCategoryCard(String title, String imagePath, Color color) {
    return GestureDetector(
                                                  onTap: () {
        debugPrint("Kategori tıklandı: $title");
        // Kategori sayfasına yönlendirme
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title kategorisi seçildi'),
            duration: const Duration(seconds: 1),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
              color,
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                        children: [
              // Icon yerleştirilecek
              /*Image.asset(
                imagePath,
                height: 40,
              ),*/
              
              const SizedBox(height: 8),
              
                          Text(
                title,
                style: const TextStyle(
                                                            color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return GestureDetector(
                            onTap: () {
        debugPrint("Devam et butonuna tıklandı");
        // Devam et butonuna basıldığında yapılacak işlem
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devam ediliyor...'),
            duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Devam Et',
          style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Günün konusu kartı - Material ve InkWell ile iyileştirilmiş
  Widget _buildTodaysTopicCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.05),
            onTap: () {
              debugPrint("Günün konusu tıklandı");
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Günün konusu açılıyor...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'GÜNÜN KONUSU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'İsim - Fiil Çekimi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Türkçe dilbilgisi kurallarını öğrenmeye devam edin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Material(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.white.withOpacity(0.2),
                          highlightColor: Colors.white.withOpacity(0.1),
                          onTap: () {
                            debugPrint("Keşfet butonuna tıklandı");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Konu detayları açılıyor...'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Keşfet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _decodeBase64Image(String? base64String) async {
    if (base64String == null || base64String.isEmpty) {
      // Boş bir Uint8List döndür
      return Uint8List(0);
    }
    
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Resim decode hatası: $e');
      // Hata durumunda da boş bir Uint8List döndür
      return Uint8List(0);
    }
  }

  // Ortak duyuru kartı bileşeni
  Widget _buildAnnouncementCard({
    required String baslik,
    required String kisaAciklama,
    String? resimBase64,
    required Color cardColor,
    required String etiket,
    required String duyuruTipi,
    String? target,
  }) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            debugPrint("Duyuru tıklandı: $baslik");
            _showAnnouncementDetails(
              context,
              baslik,
              kisaAciklama,
              resimBase64,
              target
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                gradient: resimBase64 == null || resimBase64.isEmpty
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cardColor,
                          cardColor.withOpacity(0.7),
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (resimBase64 != null && resimBase64.isNotEmpty)
                    Positioned.fill(
                      child: FutureBuilder<Uint8List>(
                        future: _decodeBase64Image(resimBase64),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Opacity(
                              opacity: 0.85,
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return ColoredBox(color: cardColor);
                          } else {
                            return ColoredBox(color: cardColor);
                          }
                        },
                      ),
                    ),
                  if (resimBase64 != null && resimBase64.isNotEmpty)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (resimBase64 == null || resimBase64.isEmpty)
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.1,
                        child: Icon(
                          _getIconForType(duyuruTipi),
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIconForType(duyuruTipi),
                              color: Colors.white.withOpacity(0.9),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              etiket,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          baslik,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kisaAciklama,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
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
          ),
        ),
      ),
    );
  }

  // Duyuru tipine göre ikon getiren yardımcı metod
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bilgilendirme':
        return Icons.info_outline_rounded;
      case 'etkinlik':
        return Icons.event_available_rounded;
      case 'duyuru':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
  
  void _showAnnouncementDetails(
    BuildContext context, 
    String title, 
    String content, 
    String? resimBase64, 
    String? target
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/dersResimleri/background.png'),
            fit: BoxFit.cover,
          ),
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Çubuk göstergesi
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Resim varsa göster
            if (resimBase64 != null && resimBase64.isNotEmpty)
              Container(
                width: double.infinity,
                height: 240,
                margin: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                child: Stack(
                  children: [
                    // Resim
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        child: Image.memory(
                          base64Decode(resimBase64),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Detay resim yükleme hatası: $error");
                            return Container(
                              color: Colors.grey.withOpacity(0.1),
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Başlık
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.campaign_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'DUYURU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Kapatma butonu
                    Positioned(
                      top: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              // Resim yoksa sadece başlık göster
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF434CDC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.campaign_rounded,
                                color: Color(0xFF434CDC),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'DUYURU',
                                style: TextStyle(
                                  color: Color(0xFF434CDC),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2A2E7B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            
            // İçerik
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A4A4A),
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ),
            
            // Alt butonlar
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
              child: target != null && target.isNotEmpty
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Hedef sayfaya yönlendirme yapılabilir
                      // Navigator.pushNamed(context, target);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF434CDC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Detayları Gör',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Kapat',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Örnek duyuruları gösteren metot
  Widget _buildSampleAnnouncements({bool excludeEvents = false}) {
    // Örnek duyurular - gerçek uygulamada Firebase'den gelecek
    final sampleAnnouncements = [
      {
        'baslik': 'Yeni Özellik: Bilgi Yarışmaları',
        'kisaAciklama': 'Arkadaşlarınız ile yarışabileceğiniz yeni bilgi yarışmaları eklendi.',
        'tip': 'bilgilendirme',
        'aktif': true,
        'resim': null,
      },
      {
        'baslik': 'Bakım Çalışması',
        'kisaAciklama': 'Yarın 03:00-05:00 saatleri arasında bakım çalışması nedeniyle hizmet verilemeyecektir.',
        'tip': 'duyuru',
        'aktif': true,
        'resim': null,
      },
      {
        'baslik': 'Yaz Kampı Kayıtları',
        'kisaAciklama': 'Yazılım geliştirme yaz kampı kayıtları başladı, katılmayı unutmayın!',
        'tip': 'etkinlik',
        'aktif': true,
        'resim': null,
      },
    ];
    
    // Eğer etkinlikleri hariç tutmak isteniyorsa filtrele
    final filteredAnnouncements = excludeEvents 
        ? sampleAnnouncements.where((a) => a['tip'] != 'etkinlik').toList()
        : sampleAnnouncements;
    
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filteredAnnouncements.length,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, top: 0, bottom: 0, right: 16),
        itemBuilder: (context, index) {
          final announcement = filteredAnnouncements[index];
          
          // Duyuru kartı renkleri - tiplere göre
          Color cardColor;
          String etiket;
          
          switch (announcement['tip']) {
            case 'bilgilendirme':
              cardColor = Colors.blue.shade700;
              etiket = 'BİLGİLENDİRME';
              break;
            case 'duyuru':
              cardColor = Colors.red.shade700;
              etiket = 'DUYURU';
              break;
            case 'etkinlik':
              cardColor = Colors.purple.shade700;
              etiket = 'ETKİNLİK';
              break;
            default:
              cardColor = Colors.grey.shade700;
              etiket = 'BİLDİRİM';
          }
          
          return _buildAnnouncementCard(
            baslik: announcement['baslik'] as String,
            kisaAciklama: announcement['kisaAciklama'] as String,
            resimBase64: announcement['resim'] as String?,
            cardColor: cardColor,
            etiket: etiket,
            duyuruTipi: announcement['tip'] as String,
            target: null,
          );
        },
                              ),
                            );
                          }
                          
  // Premium butonu için yeni widget
  Widget _buildPremiumButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: AppTheme.backgroundColorFistik,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Premium\'a Yükselt',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '₺2850',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Leaderboard ve İstatistikler
  Widget _buildLeaderboardPreview() {
    return Column(
      children: [
        // Liderlik Tablosu Butonu
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LiderlikTablosuPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Liderlik Tablosu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // İstatistiklerim Butonu
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IstatistiklerimPage(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'İstatistiklerim',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

