import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class EslestirmePage extends StatefulWidget {
  const EslestirmePage({super.key});

  @override
  State<EslestirmePage> createState() => _EslestirmePageState();
}

class _EslestirmePageState extends State<EslestirmePage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> _tumKartlar = [];
  bool _yukleniyor = true;

  static const int SEVIYE_BASINA_KART = 4; // Her seviyede 4 eşleşme (8 kart)
  int get toplamSeviye => (_tumKartlar.length / SEVIYE_BASINA_KART).ceil();

  // Oyun değişkenleri
  List<Map<String, String>> _karisikKartlar = [];
  List<bool> _kartSecildi = [];
  List<int> _eslesmisKartlar = [];
  int? _ilkSecilenKart;
  bool _kartSecimiBekliyor = false;
  int _puan = 0;
  int _enYuksekPuan = 0;
  int _kalanSure = 300;
  Timer? _sayac;
  bool _oyunBitti = false;
  int _mevcutSeviye = 0;
  bool _seviyeTamamlandi = false;

  // Animasyon kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Future<void> _kartlariYukle() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('matchingPairs')
          .get();

      List<Map<String, String>> yeniKartlar = [];
      for (var doc in snapshot.docs) {
        yeniKartlar.add({
          doc.data()['word'] as String: doc.data()['matchingWord'] as String
        });
      }

      // Tüm kartları karıştır
      yeniKartlar.shuffle(Random());

      setState(() {
        _tumKartlar = yeniKartlar;
        _yukleniyor = false;
        _yeniOyunBaslat();
      });
    } catch (e) {
      print('Hata: $e');
      setState(() {
        _yukleniyor = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kartlar yüklenirken bir hata oluştu. Lütfen tekrar deneyin.',
              style: GoogleFonts.rubik(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _enYuksekPuaniYukle();
    _kartlariYukle();
  }

  Future<void> _enYuksekPuaniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enYuksekPuan = prefs.getInt('eslestirme_en_yuksek') ?? 0;
    });
  }

  Future<void> _enYuksekPuaniKaydet() async {
    if (_puan > _enYuksekPuan) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('eslestirme_en_yuksek', _puan);
      setState(() {
        _enYuksekPuan = _puan;
      });
    }
  }

  void _yeniOyunBaslat() {
    // Tüm kartları tekrar karıştır
    _tumKartlar.shuffle(Random());
    _mevcutSeviye = 0;
    _seviyeyiYukle();
  }

  void _seviyeyiYukle() {
    // Kartları hazırla
    _karisikKartlar = [];
    List<Map<String, String>> kelimeKartlari = [];
    List<Map<String, String>> tanimKartlari = [];
    
    // Mevcut seviyenin kartlarını oluştur
    final baslangicIndex = _mevcutSeviye * SEVIYE_BASINA_KART;
    final bitisIndex = min(baslangicIndex + SEVIYE_BASINA_KART, _tumKartlar.length);
    
    // Kelimeleri ve tanımları ayrı ayrı hazırla
    for (var i = baslangicIndex; i < bitisIndex; i++) {
      final kart = _tumKartlar[i];
      kelimeKartlari.add({kart.keys.first: ''});  // Kelime kartı
      tanimKartlari.add({'': kart.values.first}); // Tanım kartı
    }
    
    // Kelimeleri ve tanımları kendi içlerinde karıştır
    kelimeKartlari.shuffle();
    tanimKartlari.shuffle();
    
    // Önce kelimeler, sonra tanımlar
    _karisikKartlar = [...kelimeKartlari, ...tanimKartlari];
    
    // Değişkenleri sıfırla
    _kartSecildi = List.generate(_karisikKartlar.length, (index) => false);
    _eslesmisKartlar = [];
    _ilkSecilenKart = null;
    _kartSecimiBekliyor = false;
    _seviyeTamamlandi = false;

    if (_mevcutSeviye == 0) {
      _puan = 0;
      _kalanSure = 300;
      _oyunBitti = false;

      // Süre sayacını başlat
      _sayac?.cancel();
      _sayac = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            if (_kalanSure > 0) {
              _kalanSure--;
            } else {
              _oyunuBitir();
            }
          });
        }
      });
    }
  }

  void _oyunuBitir() {
    _sayac?.cancel();
    _oyunBitti = true;
    _enYuksekPuaniKaydet();
    
    // Oyun bitti dialogu
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Oyun Bitti!',
          style: GoogleFonts.rubik(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Puanınız: $_puan',
              style: GoogleFonts.rubik(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'En Yüksek Puan: $_enYuksekPuan',
              style: GoogleFonts.rubik(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _yeniOyunBaslat();
            },
            child: Text(
              'Tekrar Oyna',
              style: GoogleFonts.rubik(
                color: Colors.blue[300],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog'u kapat
              Navigator.pop(context); // Oyundan çık
            },
            child: Text(
              'Çık',
              style: GoogleFonts.rubik(
                color: Colors.red[300],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _kartSec(int index) {
    if (_kartSecildi[index] || _eslesmisKartlar.contains(index) || _kartSecimiBekliyor || _seviyeTamamlandi) {
      return;
    }

    setState(() {
      _kartSecildi[index] = true;
      
      if (_ilkSecilenKart == null) {
        _ilkSecilenKart = index;
      } else {
        _kartSecimiBekliyor = true;
        
        // Eşleşme kontrolü
        final ilkKart = _karisikKartlar[_ilkSecilenKart!];
        final ikinciKart = _karisikKartlar[index];
        
        bool eslesme = false;
        if (ilkKart.keys.first.isNotEmpty && ikinciKart.values.first.isNotEmpty) {
          // İlk kart kelime, ikinci kart tanım
          final baslangicIndex = _mevcutSeviye * SEVIYE_BASINA_KART;
          final bitisIndex = min(baslangicIndex + SEVIYE_BASINA_KART, _tumKartlar.length);
          
          for (var i = baslangicIndex; i < bitisIndex; i++) {
            final kart = _tumKartlar[i];
            if (kart.keys.first == ilkKart.keys.first && 
                kart.values.first == ikinciKart.values.first) {
              eslesme = true;
              break;
            }
          }
        } else if (ilkKart.values.first.isNotEmpty && ikinciKart.keys.first.isNotEmpty) {
          // İlk kart tanım, ikinci kart kelime
          final baslangicIndex = _mevcutSeviye * SEVIYE_BASINA_KART;
          final bitisIndex = min(baslangicIndex + SEVIYE_BASINA_KART, _tumKartlar.length);
          
          for (var i = baslangicIndex; i < bitisIndex; i++) {
            final kart = _tumKartlar[i];
            if (kart.values.first == ilkKart.values.first && 
                kart.keys.first == ikinciKart.keys.first) {
              eslesme = true;
              break;
            }
          }
        }

        if (eslesme) {
          // Doğru eşleşme
          HapticFeedback.mediumImpact();
          _eslesmisKartlar.add(_ilkSecilenKart!);
          _eslesmisKartlar.add(index);
          _puan += 10;
          
          // Tüm kartlar eşleşti mi?
          if (_eslesmisKartlar.length == _karisikKartlar.length) {
            _seviyeTamamlandi = true;
            _seviyeyiTamamla();
          }
        } else {
          // Yanlış eşleşme
          HapticFeedback.heavyImpact();
          _puan = max(0, _puan - 2);
          
          // Kartları geri çevir
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _kartSecildi[_ilkSecilenKart!] = false;
                _kartSecildi[index] = false;
              });
            }
          });
        }

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _ilkSecilenKart = null;
              _kartSecimiBekliyor = false;
            });
          }
        });
      }
    });
  }

  void _seviyeyiTamamla() {
    if (_mevcutSeviye < toplamSeviye - 1) {
      // Bonus puan
      _puan += (_kalanSure ~/ 10); // Her 10 saniye için 1 bonus puan
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Seviye ${_mevcutSeviye + 1} Tamamlandı!',
            style: GoogleFonts.rubik(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tebrikler! Bir sonraki seviyeye geçmeye hazır mısınız?',
                style: GoogleFonts.rubik(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mevcut Puan: $_puan',
                style: GoogleFonts.rubik(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _mevcutSeviye++;
                  _seviyeyiYukle();
                });
              },
              child: Text(
                'Devam Et',
                style: GoogleFonts.rubik(
                  color: Colors.blue[300],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Tüm seviyeler tamamlandı
      _oyunuBitir();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sayac?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/dersResimleri/eslestirme.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SafeArea(
            child: _yukleniyor
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildOyunAlani(),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Çıkış butonu
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: Text(
                          'Oyundan Çık',
                          style: GoogleFonts.rubik(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Oyundan çıkmak istediğinize emin misiniz?',
                          style: GoogleFonts.rubik(
                            color: Colors.white70,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'İptal',
                              style: GoogleFonts.rubik(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Dialog'u kapat
                              Navigator.pop(context); // Oyundan çık
                            },
                            child: Text(
                              'Çık',
                              style: GoogleFonts.rubik(
                                color: Colors.red[300],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Puan bilgileri
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Puan: $_puan',
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'En Yüksek: $_enYuksekPuan',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Kalan süre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${_kalanSure ~/ 60}:${(_kalanSure % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kalanSure <= 10 ? Colors.red : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOyunAlani() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Sol taraf - Kelimeler
            Expanded(
              child: ListView.builder(
                itemCount: _karisikKartlar.length ~/ 2,
                itemBuilder: (context, index) {
                  final kart = _karisikKartlar[index];
                  final secili = _kartSecildi[index];
                  final eslesti = _eslesmisKartlar.contains(index);
                  final rastgeleRenk = _renkler[index % _renkler.length];
                  
                  // Sadece kelime kartlarını göster
                  if (kart.keys.first.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _kartSec(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80,
                        decoration: BoxDecoration(
                          color: eslesti 
                              ? Colors.green.withOpacity(0.3)
                              : secili 
                                  ? Colors.blue.withOpacity(0.3)
                                  : rastgeleRenk.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: eslesti 
                                ? Colors.green
                                : secili 
                                    ? Colors.blue
                                    : rastgeleRenk,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (eslesti 
                                  ? Colors.green
                                  : secili 
                                      ? Colors.blue
                                      : rastgeleRenk).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: secili || eslesti
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      kart.keys.first,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.rubik(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.question_mark,
                                    size: 32,
                                    color: rastgeleRenk.withOpacity(0.7),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Sağ taraf - Tanımlar
            Expanded(
              child: ListView.builder(
                itemCount: _karisikKartlar.length ~/ 2,
                itemBuilder: (context, index) {
                  final actualIndex = index + (_karisikKartlar.length ~/ 2);
                  final kart = _karisikKartlar[actualIndex];
                  final secili = _kartSecildi[actualIndex];
                  final eslesti = _eslesmisKartlar.contains(actualIndex);
                  final rastgeleRenk = _renkler[(index + 5) % _renkler.length];
                  
                  // Sadece tanım kartlarını göster
                  if (kart.values.first.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _kartSec(actualIndex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80,
                        decoration: BoxDecoration(
                          color: eslesti 
                              ? Colors.green.withOpacity(0.3)
                              : secili 
                                  ? Colors.blue.withOpacity(0.3)
                                  : rastgeleRenk.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: eslesti 
                                ? Colors.green
                                : secili 
                                    ? Colors.blue
                                    : rastgeleRenk,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (eslesti 
                                  ? Colors.green
                                  : secili 
                                      ? Colors.blue
                                      : rastgeleRenk).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: secili || eslesti
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      kart.values.first,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.rubik(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.question_mark,
                                    size: 32,
                                    color: rastgeleRenk.withOpacity(0.7),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Renk listesi
  final List<Color> _renkler = [
    Colors.purple,
    Colors.blue,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.red,
    Colors.amber,
    Colors.green,
    Colors.cyan,
    Colors.deepOrange,
    Colors.lime,
    Colors.lightBlue,
    Colors.deepPurple,
    Colors.yellow,
    Colors.brown,
  ];
} 