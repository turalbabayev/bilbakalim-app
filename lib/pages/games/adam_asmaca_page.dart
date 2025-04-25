import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdamAsmacaPage extends StatefulWidget {
  const AdamAsmacaPage({Key? key}) : super(key: key);

  @override
  State<AdamAsmacaPage> createState() => _AdamAsmacaPageState();
}

class _AdamAsmacaPageState extends State<AdamAsmacaPage> with TickerProviderStateMixin {
  List<Map<String, String>> _sorular = [];

  String _secilenKelime = '';
  String _secilenSoru = '';
  List<bool> _bulunanHarfler = [];
  Set<String> _tahminEdilenHarfler = {};
  int _kalanHak = 6;
  int _puan = 0;
  int _enYuksekPuan = 0;
  int _streak = 0;
  bool _oyunBitti = false;
  bool _kazandi = false;
  
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _swingController;
  late final Animation<double> _swingAnimation;

  final List<String> _alfabe = [
    'A', 'B', 'C', 'Ç', 'D', 'E', 'F', 'G', 'Ğ', 'H',
    'I', 'İ', 'J', 'K', 'L', 'M', 'N', 'O', 'Ö', 'P',
    'R', 'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z'
  ];

  final List<String> _karakterDurumlari = [
    'adam_butun.png',     // Başlangıç durumu - tam karakter
    'tek_bacak.png',      // 1 yanlış - bir bacağı kaybolur
    'iki_bacak.png',      // 2 yanlış - iki bacağı kaybolur
    'govdesiz.png',       // 3 yanlış - gövdesi kaybolur
    'tek_kol.png',        // 4 yanlış - bir kolu kaybolur
    'sadece_kafa.png',    // 5 yanlış - sadece kafası kalır
    'bos_salincak.png',   // 6 yanlış - salıncaktan düşer
  ];

  String get _guncelKarakterResmi => _karakterDurumlari[6 - _kalanHak];

  Future<void> _sorulariYukle() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hangmanQuestions')
          .get();

      setState(() {
        _sorular = snapshot.docs.map((doc) {
          return {
            'soru': doc.data()['question'] as String,
            'cevap': (doc.data()['answer'] as String).toUpperCase(),
          };
        }).toList();
        
        if (_sorular.isNotEmpty) {
          final secilenIndex = Random().nextInt(_sorular.length);
          _secilenKelime = _sorular[secilenIndex]['cevap']!;
          _secilenSoru = _sorular[secilenIndex]['soru']!;
          _bulunanHarfler = List.filled(_secilenKelime.length, false);
        }
      });
    } catch (e) {
      print('Hata: $e');
    }
  }

  void _normalSallanma() {
    _swingController.duration = const Duration(seconds: 2);
    _swingController.stop();
    _swingController.reset();
    _swingController.repeat(reverse: true);
  }

  void _hizliSallanma() {
    _swingController.duration = const Duration(milliseconds: 500);
    _swingController.stop();
    _swingController.reset();
    _swingController.repeat(reverse: true);
  }

  @override
  void initState() {
    super.initState();
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _shakeAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _swingAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _swingController,
      curve: Curves.easeInOut,
    ));

    _puaniYukle();
    _sorulariYukle();
    _normalSallanma();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scaleController.dispose();
    _swingController.dispose();
    super.dispose();
  }

  Future<void> _puaniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enYuksekPuan = prefs.getInt('adam_asmaca_en_yuksek_puan') ?? 0;
    });
  }

  Future<void> _puaniKaydet() async {
    if (_puan > _enYuksekPuan) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('adam_asmaca_en_yuksek_puan', _puan);
      setState(() {
        _enYuksekPuan = _puan;
      });
    }
  }

  void _yeniOyun() {
    if (_sorular.isEmpty) return;
    
    setState(() {
      final secilenIndex = Random().nextInt(_sorular.length);
      _secilenKelime = _sorular[secilenIndex]['cevap']!;
      _secilenSoru = _sorular[secilenIndex]['soru']!;
      _bulunanHarfler = List.filled(_secilenKelime.length, false);
      _tahminEdilenHarfler.clear();
      _kalanHak = 6;
      _oyunBitti = false;
      _kazandi = false;
      _puan = 0;
    });
    
    _normalSallanma();
  }

  void _harfTahmin(String harf) {
    if (_oyunBitti || _tahminEdilenHarfler.contains(harf)) return;
    
    HapticFeedback.mediumImpact();
    bool harfVar = false;
    
    setState(() {
      _tahminEdilenHarfler.add(harf);
      
      for (int i = 0; i < _secilenKelime.length; i++) {
        if (_secilenKelime[i] == harf) {
          _bulunanHarfler[i] = true;
          harfVar = true;
        }
      }
      
      if (!harfVar) {
        _kalanHak--;
        _streak = 0;
        
        _hizliSallanma();
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_oyunBitti) {
            _normalSallanma();
          }
        });
        
        _shakeController.forward().then((_) => _shakeController.reverse());
      } else {
        _scaleController.forward().then((_) => _scaleController.reverse());
      }
      
      if (_bulunanHarfler.every((element) => element)) {
        _oyunBitti = true;
        _kazandi = true;
        _streak++;
        int bonus = _streak >= 3 ? 20 : 0;
        _puan += 50 + bonus;
        _puaniKaydet();
        _swingController.stop();
      }
      
      if (_kalanHak <= 0) {
        _oyunBitti = true;
        _kazandi = false;
        _streak = 0;
        _swingController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/dersResimleri/${_guncelKarakterResmi}',
              fit: BoxFit.cover,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _secilenSoru,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_streak >= 3)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.red],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_streak Seri!',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_puan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_enYuksekPuan',
                                    style: GoogleFonts.poppins(
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
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Center(
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _secilenKelime.length,
                                  (index) => Container(
                                    width: 32,
                                    height: 40,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: _bulunanHarfler[index]
                                          ? Colors.green.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _bulunanHarfler[index] ? _secilenKelime[index] : '',
                                        style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: _alfabe.map((harf) {
                            bool tahminEdildi = _tahminEdilenHarfler.contains(harf);
                            bool dogruTahmin = false;
                            
                            if (tahminEdildi) {
                              dogruTahmin = _secilenKelime.contains(harf);
                            }

                            return SizedBox(
                              width: 32,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: tahminEdildi ? null : () => _harfTahmin(harf),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: tahminEdildi
                                      ? (dogruTahmin ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8))
                                      : Colors.white.withOpacity(0.2),
                                  disabledBackgroundColor: tahminEdildi
                                      ? (dogruTahmin ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8))
                                      : Colors.grey.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  harf,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_oyunBitti)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kazandi ? Colors.green.withOpacity(0.9) : Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _kazandi ? 'Tebrikler!' : 'Oyun Bitti!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (!_kazandi) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Doğru kelime: $_secilenKelime',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _yeniOyun,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              'Yeni Oyun',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _kazandi ? Colors.green : Colors.red,
                              ),
                            ),
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