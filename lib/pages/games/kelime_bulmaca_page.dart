import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class KelimeBulmacaPage extends StatefulWidget {
  const KelimeBulmacaPage({super.key});

  @override
  State<KelimeBulmacaPage> createState() => _KelimeBulmacaPageState();
}

class _KelimeBulmacaPageState extends State<KelimeBulmacaPage> with SingleTickerProviderStateMixin {
  Map<String, String> _sorular = {};
  bool _yukleniyor = true;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _shakeAnimation;
  
  // Oyun değişkenleri
  String _secilenKelime = '';
  String _soru = '';
  List<String> _karisikHarfler = [];
  List<bool> _harfSecildi = [];
  List<int> _secilenHarfler = [];
  List<String> _girilenHarfler = [];
  int _puan = 0;
  int _enYuksekPuan = 0;
  bool _oyunBitti = false;
  int _seviye = 1;
  int _dogruCevapSayisi = 0;
  
  // Harf pozisyonları
  List<Offset> _harfPozisyonlari = [];
  double _daireCap = 250;
  
  // Çizgi çizme değişkenleri
  bool _cizimBasladi = false;
  Offset? _geciciCizgiSonu;
  int? _aktifHarfIndex;
  bool _harfUzerinde = false;
  bool _sonHarftenDevamEdebilir = false;
  bool _yanlisCevap = false;

  Future<void> _sorulariYukle() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wordPuzzles')
          .get();

      Map<String, String> yeniSorular = {};
      for (var doc in snapshot.docs) {
        yeniSorular[doc.data()['answer'].toString().toUpperCase()] = doc.data()['question'] as String;
      }

      setState(() {
        _sorular = yeniSorular;
        _yukleniyor = false;
        if (_sorular.isNotEmpty) {
          _yeniOyunBaslat();
        }
      });
    } catch (e) {
      print('Hata: $e');
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0), end: const Offset(0.05, 0)),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(-0.05, 0), end: const Offset(0, 0)),
        weight: 1.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _enYuksekPuaniYukle();
    _sorulariYukle();
  }

  Future<void> _enYuksekPuaniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enYuksekPuan = prefs.getInt('kelime_bulmaca_en_yuksek') ?? 0;
    });
  }

  Future<void> _enYuksekPuaniKaydet() async {
    if (_puan > _enYuksekPuan) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('kelime_bulmaca_en_yuksek', _puan);
      setState(() {
        _enYuksekPuan = _puan;
      });
    }
  }

  void _yeniOyunBaslat() {
    if (_sorular.isEmpty) return;
    
    // Yeni soru seç
    final soruIndex = Random().nextInt(_sorular.length);
    _secilenKelime = _sorular.keys.elementAt(soruIndex);
    _soru = _sorular[_secilenKelime]!;
    
    // Harfleri karıştır
    _karisikHarfler = _secilenKelime.split('')..shuffle();
    _harfSecildi = List.generate(_karisikHarfler.length, (index) => false);
    
    // Değişkenleri sıfırla
    _secilenHarfler = [];
    _girilenHarfler = List.generate(_secilenKelime.length, (index) => '');
    _oyunBitti = false;
    
    // Harf pozisyonlarını hesapla
    _harfPozisyonlariniHesapla();
  }

  void _harfPozisyonlariniHesapla() {
    _harfPozisyonlari = [];
    final harfSayisi = _karisikHarfler.length;
    
    for (int i = 0; i < harfSayisi; i++) {
      final angle = (2 * pi * i) / harfSayisi;
      final x = _daireCap / 2 * cos(angle);
      final y = _daireCap / 2 * sin(angle);
      _harfPozisyonlari.add(Offset(x, y));
    }
  }

  void _harfSec(int index) {
    if (_oyunBitti || _harfSecildi[index]) return;

    setState(() {
      _harfSecildi[index] = true;
      _secilenHarfler.add(index);
      _sonHarftenDevamEdebilir = true;
      
      if (_secilenHarfler.length <= _secilenKelime.length) {
        _girilenHarfler[_secilenHarfler.length - 1] = _karisikHarfler[index];
      }
      
      if (_secilenHarfler.length == _secilenKelime.length) {
        final girilenKelime = _girilenHarfler.join();
        if (girilenKelime == _secilenKelime) {
          _oyunBitti = true;
          _dogruCevapSayisi++;
          
          if (_dogruCevapSayisi % 3 == 0) {
            _seviye++;
            _puan += 50;
          }
          
          _puan += (_secilenKelime.length * 10) * _seviye;
          _enYuksekPuaniKaydet();
          
          // Doğru cevap animasyonu
          _animationController.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  // Harfleri yeşil yap ve büyüt
                  for (var i = 0; i < _harfSecildi.length; i++) {
                    _harfSecildi[i] = true;
                  }
                });
                
                // Titreşim efekti
                HapticFeedback.mediumImpact();
                
                // Yeni soruya geç
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _animationController.reverse();
                      _yeniOyunBaslat();
                    });
                  }
                });
              }
            });
          });
        } else {
          // Yanlış cevap animasyonu
          setState(() {
            _yanlisCevap = true;
            _harfSecildi = List.generate(_karisikHarfler.length, (index) => false);
            _secilenHarfler = [];
            _girilenHarfler = List.generate(_secilenKelime.length, (index) => '');
            _cizimBasladi = false;
            _geciciCizgiSonu = null;
            _aktifHarfIndex = null;
            _sonHarftenDevamEdebilir = false;
            _puan = max(0, _puan - 5);
          });

          // Titreşim ve shake animasyonu
          HapticFeedback.heavyImpact();
          _animationController.forward().then((_) {
            _animationController.reverse().then((_) {
              setState(() {
                _yanlisCevap = false;
              });
            });
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan resmi
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Image.asset(
                'assets/dersResimleri/kelime_bulmaca.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Karartma katmanı
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Oyun içeriği
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSoru(),
                _buildHarfDairesi(),
                _buildGirilenKelime(),
              ],
            ),
          ),
        ],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Seviye $_seviye',
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoru() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb,
            color: Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _soru,
              style: GoogleFonts.rubik(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarfDairesi() {
    return Expanded(
      child: Center(
        child: SlideTransition(
          position: _yanlisCevap ? _shakeAnimation : const AlwaysStoppedAnimation<Offset>(Offset.zero),
          child: Container(
            width: _daireCap + 80,
            height: _daireCap + 80,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white24,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(_daireCap + 80, _daireCap + 80),
                  painter: _CizgiPainter(
                    harfPozisyonlari: _harfPozisyonlari,
                    secilenHarfler: _secilenHarfler,
                    geciciCizgi: _cizimBasladi && _aktifHarfIndex != null ? 
                      Offset(_harfPozisyonlari[_aktifHarfIndex!].dx + (_daireCap + 80) / 2,
                            _harfPozisyonlari[_aktifHarfIndex!].dy + (_daireCap + 80) / 2) : null,
                    geciciCizgiSonu: _geciciCizgiSonu,
                    offset: Offset((_daireCap + 80) / 2, (_daireCap + 80) / 2),
                  ),
                ),
                for (int i = 0; i < _karisikHarfler.length; i++)
                  Positioned(
                    left: _harfPozisyonlari[i].dx + (_daireCap + 80) / 2 - 25,
                    top: _harfPozisyonlari[i].dy + (_daireCap + 80) / 2 - 25,
                    child: GestureDetector(
                      onPanStart: (details) {
                        if (!_harfSecildi[i] || (_sonHarftenDevamEdebilir && _secilenHarfler.isNotEmpty && _secilenHarfler.last == i)) {
                          setState(() {
                            _cizimBasladi = true;
                            _aktifHarfIndex = i;
                            if (!_harfSecildi[i]) {
                              _harfSec(i);
                            }
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (_cizimBasladi) {
                          setState(() {
                            _geciciCizgiSonu = details.localPosition + 
                                Offset(_harfPozisyonlari[i].dx + (_daireCap + 80) / 2 - 25,
                                     _harfPozisyonlari[i].dy + (_daireCap + 80) / 2 - 25);
                            
                            for (int j = 0; j < _karisikHarfler.length; j++) {
                              if (j != i && !_harfSecildi[j]) {
                                final harfMerkezi = Offset(
                                  _harfPozisyonlari[j].dx + (_daireCap + 80) / 2,
                                  _harfPozisyonlari[j].dy + (_daireCap + 80) / 2,
                                );
                                
                                final mesafe = (_geciciCizgiSonu! - harfMerkezi).distance;
                                if (mesafe < 30 && !_harfUzerinde) {
                                  _harfUzerinde = true;
                                  _harfSec(j);
                                  _aktifHarfIndex = j;
                                  break;
                                } else if (mesafe >= 30) {
                                  _harfUzerinde = false;
                                }
                              }
                            }
                          });
                        }
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _cizimBasladi = false;
                          _geciciCizgiSonu = null;
                          _harfUzerinde = false;
                        });
                      },
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _harfSecildi[i]
                                ? (_secilenHarfler.isNotEmpty && _secilenHarfler.last == i)
                                    ? Colors.blue.shade300  // Son seçilen harf mavi
                                    : Colors.green.shade300
                                : Colors.white24,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _harfSecildi[i] 
                                    ? (_secilenHarfler.isNotEmpty && _secilenHarfler.last == i)
                                        ? Colors.blue.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _karisikHarfler[i],
                              style: GoogleFonts.rubik(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _harfSecildi[i] ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildGirilenKelime() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: List.generate(_secilenKelime.length, (index) {
          return Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _girilenHarfler[index],
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _CizgiPainter extends CustomPainter {
  final List<Offset> harfPozisyonlari;
  final List<int> secilenHarfler;
  final Offset? geciciCizgi;
  final Offset? geciciCizgiSonu;
  final Offset offset;

  _CizgiPainter({
    required this.harfPozisyonlari,
    required this.secilenHarfler,
    this.geciciCizgi,
    this.geciciCizgiSonu,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Seçili harfler arasındaki çizgiler
    for (int i = 0; i < secilenHarfler.length - 1; i++) {
      final start = harfPozisyonlari[secilenHarfler[i]] + offset;
      final end = harfPozisyonlari[secilenHarfler[i + 1]] + offset;
      canvas.drawLine(start, end, paint);
    }

    // Geçici çizgi
    if (geciciCizgi != null && geciciCizgiSonu != null) {
      canvas.drawLine(geciciCizgi!, geciciCizgiSonu!, paint);
    }
  }

  @override
  bool shouldRepaint(_CizgiPainter oldDelegate) => true;
} 