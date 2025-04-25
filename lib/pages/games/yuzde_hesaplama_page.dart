import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class YuzdeHesaplamaPage extends StatefulWidget {
  const YuzdeHesaplamaPage({super.key});

  @override
  State<YuzdeHesaplamaPage> createState() => _YuzdeHesaplamaPageState();
}

class _YuzdeHesaplamaPageState extends State<YuzdeHesaplamaPage> with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  
  bool _oyunBasladi = false;
  int _sayi1 = 0;
  int _sayi2 = 0;
  String _tahmin = '';
  int _puan = 0;
  int _enYuksekPuan = 0;
  int _kalanSure = 60;
  Timer? _sayac;
  int _streak = 0;
  int _dogruSayisi = 0;
  int _yanlisSayisi = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _enYuksekPuaniYukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/dersResimleri/yuzde_kac_arkaplan.png'),
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
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                if (!_oyunBasladi)
                  _buildBaslangicEkrani()
                else
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSoruKarti(),
                        const SizedBox(height: 30),
                        _buildCevapAlani(),
                      ],
                    ),
                  ),
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

  Widget _buildBaslangicEkrani() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '100\'de Kaç?',
              style: GoogleFonts.rubik(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'En Yüksek Puan: $_enYuksekPuan',
              style: GoogleFonts.rubik(
                fontSize: 24,
                color: Colors.white70,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _oyunuBaslat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                  shadowColor: Colors.green.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BAŞLA',
                      style: GoogleFonts.rubik(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoruKarti() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$_sayi1\'in yüzde $_sayi2\'si kaçtır?',
            style: GoogleFonts.rubik(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCevapAlani() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: GoogleFonts.rubik(
                fontSize: 30,
                color: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _tahmin = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cevabınız',
                hintStyle: GoogleFonts.rubik(
                  color: Colors.white54,
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.keyboard_hide, color: Colors.white70),
                  onPressed: () => FocusScope.of(context).unfocus(),
                ),
              ),
              onSubmitted: (value) => _cevapKontrol(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _tahmin.isEmpty ? null : _cevapKontrol,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.blue.withOpacity(0.3),
                disabledForegroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: Colors.blue.withOpacity(0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'KONTROL ET',
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _oyunuBaslat() {
    setState(() {
      _oyunBasladi = true;
      _puan = 0;
      _kalanSure = 60;
      _streak = 0;
      _dogruSayisi = 0;
      _yanlisSayisi = 0;
      _yeniSoru();
    });

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

  void _yeniSoru() {
    setState(() {
      _sayi1 = Random().nextInt(901) + 100; // 100-1000 arası
      _sayi2 = Random().nextInt(91) + 10;   // 10-100 arası
      _controller.clear();
      _tahmin = '';
    });
  }

  void _cevapKontrol() {
    if (_tahmin.isEmpty) return;

    final cevap = (_sayi1 * _sayi2 / 100).round();
    final kullaniciCevabi = int.tryParse(_tahmin) ?? 0;
    
    if (kullaniciCevabi == cevap) {
      // Doğru cevap
      setState(() {
        _dogruSayisi++;
        _streak++;
        _puan += 10 + (_streak > 1 ? _streak * 2 : 0); // Streak bonusu
        HapticFeedback.mediumImpact();
      });
    } else {
      // Yanlış cevap
      setState(() {
        _yanlisSayisi++;
        _streak = 0;
        _puan = max(0, _puan - 2);
        HapticFeedback.heavyImpact();
      });
    }
    
    // Her durumda yeni soruya geç
    _controller.clear();
    _tahmin = '';
    _yeniSoru();
  }

  void _oyunuBitir() {
    _sayac?.cancel();
    _enYuksekPuaniKaydet();
    
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Doğru: $_dogruSayisi',
                            style: GoogleFonts.rubik(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Yanlış: $_yanlisSayisi',
                            style: GoogleFonts.rubik(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Doğruluk: ${_dogruSayisi + _yanlisSayisi > 0 ? ((_dogruSayisi / (_dogruSayisi + _yanlisSayisi)) * 100).toStringAsFixed(1) : '0.0'}%',
                    style: GoogleFonts.rubik(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _oyunuBaslat();
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

  Future<void> _enYuksekPuaniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enYuksekPuan = prefs.getInt('yuzde_en_yuksek') ?? 0;
    });
  }

  Future<void> _enYuksekPuaniKaydet() async {
    if (_puan > _enYuksekPuan) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('yuzde_en_yuksek', _puan);
      setState(() {
        _enYuksekPuan = _puan;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _sayac?.cancel();
    super.dispose();
  }
} 