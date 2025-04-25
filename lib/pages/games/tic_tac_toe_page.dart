import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/services.dart';

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  
  // Oyun değişkenleri
  List<String> _tahta = List.filled(9, '');
  bool _oyunBitti = false;
  bool _berabere = false;
  String _kazanan = '';
  bool _oyuncuSirasi = true; // true = X (oyuncu), false = O (sistem)
  int _oyuncuPuan = 0;
  int _sistemPuan = 0;
  int _enYuksekPuan = 0;

  @override
  void initState() {
    super.initState();
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
            image: const AssetImage('assets/dersResimleri/xox_arkaplan.png'),
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
                _buildOyunTahtasi(),
                const SizedBox(height: 20),
                _buildSiraBilgisi(),
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
                          Navigator.pop(context);
                          Navigator.pop(context);
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
          // Skor
          Row(
            children: [
              Column(
                children: [
                  Text(
                    'SİZ',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$_oyuncuPuan',
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '-',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    'SİSTEM',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '$_sistemPuan',
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOyunTahtasi() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _hamleYap(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  _tahta[index],
                  style: GoogleFonts.rubik(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: _tahta[index] == 'X' ? Colors.blue : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSiraBilgisi() {
    if (_oyunBitti) {
      String mesaj = _berabere ? 'Berabere!' : (_kazanan == 'X' ? 'Tebrikler, Kazandınız!' : 'Sistem Kazandı!');
      Color renk = _berabere ? Colors.orange : (_kazanan == 'X' ? Colors.blue : Colors.red);
      
      return Column(
        children: [
          Text(
            mesaj,
            style: GoogleFonts.rubik(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: renk,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _yeniOyun,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: Colors.green.withOpacity(0.5),
            ),
            child: Text(
              'Yeni Oyun',
              style: GoogleFonts.rubik(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: _oyuncuSirasi ? Colors.blue.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _oyuncuSirasi ? 'Sizin Sıranız (X)' : 'Sistem Düşünüyor... (O)',
        style: GoogleFonts.rubik(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _oyuncuSirasi ? Colors.blue : Colors.red,
        ),
      ),
    );
  }

  void _hamleYap(int index) {
    if (!_oyuncuSirasi || _tahta[index].isNotEmpty || _oyunBitti) return;

    setState(() {
      _tahta[index] = 'X';
      _oyuncuSirasi = false;
    });

    if (_kazananKontrol('X')) {
      _oyunuBitir('X');
      return;
    }

    if (_beraberlikKontrol()) {
      _oyunuBitir('');
      return;
    }

    // Sistem hamlesi
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _sistemHamlesi();
    });
  }

  void _sistemHamlesi() {
    // Zorluk seviyesi (0-100 arası)
    int zorlukSeviyesi = 65; // %65 ihtimalle akıllı hamle yapacak
    
    if (Random().nextInt(100) < zorlukSeviyesi) {
      // Akıllı hamle
      // Kazanma hamlesi var mı?
      int kazanmaHamlesi = _kazanmaHamlesiBul('O');
      if (kazanmaHamlesi != -1) {
        _hamleyiUygula(kazanmaHamlesi);
        return;
      }

      // Rakibin kazanma hamlesini engelle
      int engelHamlesi = _kazanmaHamlesiBul('X');
      if (engelHamlesi != -1) {
        _hamleyiUygula(engelHamlesi);
        return;
      }

      // Merkez boşsa %70 ihtimalle al
      if (_tahta[4].isEmpty && Random().nextInt(100) < 70) {
        _hamleyiUygula(4);
        return;
      }
    }

    // Rastgele hamle yap
    List<int> bosYerler = [];
    for (int i = 0; i < 9; i++) {
      if (_tahta[i].isEmpty) {
        bosYerler.add(i);
      }
    }
    
    if (bosYerler.isNotEmpty) {
      bosYerler.shuffle();
      _hamleyiUygula(bosYerler.first);
    }
  }

  void _hamleyiUygula(int index) {
    setState(() {
      _tahta[index] = 'O';
      _oyuncuSirasi = true;
    });

    if (_kazananKontrol('O')) {
      _oyunuBitir('O');
      return;
    }

    if (_beraberlikKontrol()) {
      _oyunuBitir('');
    }
  }

  int _kazanmaHamlesiBul(String oyuncu) {
    // Yatay kontrol
    for (int i = 0; i < 9; i += 3) {
      if (_tahta[i] == oyuncu && _tahta[i + 1] == oyuncu && _tahta[i + 2].isEmpty) return i + 2;
      if (_tahta[i] == oyuncu && _tahta[i + 2] == oyuncu && _tahta[i + 1].isEmpty) return i + 1;
      if (_tahta[i + 1] == oyuncu && _tahta[i + 2] == oyuncu && _tahta[i].isEmpty) return i;
    }

    // Dikey kontrol
    for (int i = 0; i < 3; i++) {
      if (_tahta[i] == oyuncu && _tahta[i + 3] == oyuncu && _tahta[i + 6].isEmpty) return i + 6;
      if (_tahta[i] == oyuncu && _tahta[i + 6] == oyuncu && _tahta[i + 3].isEmpty) return i + 3;
      if (_tahta[i + 3] == oyuncu && _tahta[i + 6] == oyuncu && _tahta[i].isEmpty) return i;
    }

    // Çapraz kontrol
    if (_tahta[0] == oyuncu && _tahta[4] == oyuncu && _tahta[8].isEmpty) return 8;
    if (_tahta[0] == oyuncu && _tahta[8] == oyuncu && _tahta[4].isEmpty) return 4;
    if (_tahta[4] == oyuncu && _tahta[8] == oyuncu && _tahta[0].isEmpty) return 0;

    if (_tahta[2] == oyuncu && _tahta[4] == oyuncu && _tahta[6].isEmpty) return 6;
    if (_tahta[2] == oyuncu && _tahta[6] == oyuncu && _tahta[4].isEmpty) return 4;
    if (_tahta[4] == oyuncu && _tahta[6] == oyuncu && _tahta[2].isEmpty) return 2;

    return -1;
  }

  bool _kazananKontrol(String oyuncu) {
    // Yatay kontrol
    for (int i = 0; i < 9; i += 3) {
      if (_tahta[i] == oyuncu && _tahta[i + 1] == oyuncu && _tahta[i + 2] == oyuncu) return true;
    }

    // Dikey kontrol
    for (int i = 0; i < 3; i++) {
      if (_tahta[i] == oyuncu && _tahta[i + 3] == oyuncu && _tahta[i + 6] == oyuncu) return true;
    }

    // Çapraz kontrol
    if (_tahta[0] == oyuncu && _tahta[4] == oyuncu && _tahta[8] == oyuncu) return true;
    if (_tahta[2] == oyuncu && _tahta[4] == oyuncu && _tahta[6] == oyuncu) return true;

    return false;
  }

  bool _beraberlikKontrol() {
    return !_tahta.contains('');
  }

  void _oyunuBitir(String kazanan) {
    setState(() {
      _oyunBitti = true;
      _kazanan = kazanan;
      _berabere = kazanan.isEmpty;
      
      if (!_berabere) {
        if (kazanan == 'X') {
          _oyuncuPuan++;
          if (_oyuncuPuan > _enYuksekPuan) {
            _enYuksekPuan = _oyuncuPuan;
            _enYuksekPuaniKaydet();
          }
        } else {
          _sistemPuan++;
        }
      }
    });
  }

  void _yeniOyun() {
    setState(() {
      _tahta = List.filled(9, '');
      _oyunBitti = false;
      _berabere = false;
      _kazanan = '';
      _oyuncuSirasi = true;
    });
  }

  Future<void> _enYuksekPuaniYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enYuksekPuan = prefs.getInt('xox_en_yuksek') ?? 0;
    });
  }

  Future<void> _enYuksekPuaniKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xox_en_yuksek', _enYuksekPuan);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
} 