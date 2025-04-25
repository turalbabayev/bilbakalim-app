import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/pages/bolumler/test_screen/question_screen.dart' show QuestionPage;
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilbakalim/pages/premium_page.dart';

class SoruCarkiPage extends StatefulWidget {
  const SoruCarkiPage({super.key});

  @override
  State<SoruCarkiPage> createState() => _SoruCarkiPageState();
}

class _SoruCarkiPageState extends State<SoruCarkiPage> {
  final StreamController<int> _controller = StreamController<int>.broadcast();
  List<Map<String, dynamic>> konular = [];
  bool isLoading = true;
  String? secilenKonu;
  String? secilenKonuId;
  int _selectedIndex = 0;
  bool sorularYukleniyor = false;
  late AudioPlayer _audioPlayer;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _konulariGetir();
    _initAudio();
  }

  Future<void> _konulariGetir() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('konular').get();
      setState(() {
        konular = snapshot.docs
            .map((doc) {
              final baslik = doc.data()['baslik'] as String?;
              if (baslik == null || baslik.length > 20) return null;
              return {
                'id': doc.id,
                'baslik': baslik,
              };
            })
            .where((konu) => konu != null)
            .cast<Map<String, dynamic>>()
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Konular çekilirken hata: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setAsset('assets/sounds/wheel.mp3');
    await _audioPlayer.setLoopMode(LoopMode.one); // Ses sürekli çalsın
  }

  void _startSpinning() {
    setState(() {
      _isSpinning = true;
    });
    _audioPlayer.play();
  }

  void _stopSpinning() {
    setState(() {
      _isSpinning = false;
    });
    _audioPlayer.stop();
  }

  Future<void> _sorulariGetirVeTestOlustur() async {
    if (secilenKonuId == null) return;

    // Premium kontrolü
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final isPremium = userDoc.data()?['premium'] ?? false;
      
      if (!isPremium) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Premium Özellik',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bu özelliği kullanabilmek için premium üyelik gereklidir.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Vazgeç',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PremiumPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Premium Ol',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
        );
        return;
      }
    }

    setState(() {
      sorularYukleniyor = true;
    });

    try {
      print('Seçilen konu ID: $secilenKonuId');
      
      // Önce konunun altındaki alt konuları çekelim
      final altKonularSnapshot = await FirebaseFirestore.instance
          .collection('konular')
          .doc(secilenKonuId)
          .collection('altkonular')
          .get();

      if (altKonularSnapshot.docs.isEmpty) {
        setState(() {
          sorularYukleniyor = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu konuda henüz alt konu bulunmamaktadır')),
        );
        return;
      }

      // Rastgele bir alt konu seçelim
      final rastgeleAltKonu = altKonularSnapshot.docs[Fortune.randomInt(0, altKonularSnapshot.docs.length)];
      print('Seçilen alt konu: ${rastgeleAltKonu.data()['baslik']}');

      // Seçilen alt konudan rastgele 10 soru çekelim
      final sorularSnapshot = await FirebaseFirestore.instance
          .collection('konular')
          .doc(secilenKonuId)
          .collection('altkonular')
          .doc(rastgeleAltKonu.id)
          .collection('sorular')
          .get();

      if (sorularSnapshot.docs.isEmpty) {
        setState(() {
          sorularYukleniyor = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu konuda henüz soru bulunmamaktadır')),
        );
        return;
      }

      // Tüm soruları karıştır ve ilk 10 tanesini al
      final tumSorular = sorularSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      tumSorular.shuffle();
      final secilenSorular = tumSorular.take(10).toList();

      print('${secilenSorular.length} soru seçildi');

      setState(() {
        sorularYukleniyor = false;
      });

      if (!mounted) return;
      
      // Soru çözme sayfasına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionPage(
            bolumIndex: secilenKonuId ?? '',
            altKonuIndex: rastgeleAltKonu.id,
          ),
        ),
      );

    } catch (e) {
      print('Sorular çekilirken hata: $e');
      setState(() {
        sorularYukleniyor = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sorular yüklenirken bir hata oluştu')),
      );
    }
  }

  void _carkiCevir() {
    if (konular.isEmpty) return;
    final random = Fortune.randomInt(0, konular.length);
    _controller.add(random);
    _selectedIndex = random;
    setState(() {
      secilenKonu = null;
      secilenKonuId = null;
    });
  }

  @override
  void dispose() {
    _controller.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: Stack(
        children: [
          // Arkaplan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/dersResimleri/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    top: statusBarHeight + 12,
                    bottom: 16,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
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
                              child: const Icon(
                                Icons.arrow_back_ios_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Soru Çarkı',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // İçerik
          Positioned.fill(
            top: statusBarHeight + 56,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : konular.isEmpty
                    ? const Center(child: Text('Konular yüklenemedi'))
                    : Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: FortuneWheel(
                                selected: _controller.stream,
                                animateFirst: false,
                                physics: CircularPanPhysics(
                                  duration: const Duration(seconds: 1),
                                  curve: Curves.decelerate,
                                ),
                                onAnimationStart: () {
                                  _startSpinning();
                                },
                                onAnimationEnd: () {
                                  _stopSpinning();
                                  setState(() {
                                    secilenKonu = konular[_selectedIndex]['baslik'];
                                    secilenKonuId = konular[_selectedIndex]['id'];
                                  });
                                },
                                items: konular
                                    .map((konu) => FortuneItem(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              konu['baslik'],
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, -5),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                if (secilenKonu != null)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.primaryColor, AppTheme.primaryColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
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
                                    child: Column(
                                      children: [
                                        Text(
                                          'Seçilen Konu:',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          secilenKonu!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: sorularYukleniyor ? null : _sorulariGetirVeTestOlustur,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: AppTheme.primaryColor,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (sorularYukleniyor)
                                                Container(
                                                  width: 16,
                                                  height: 16,
                                                  margin: const EdgeInsets.only(right: 8),
                                                  child: const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                                  ),
                                                ),
                                              Text(
                                                sorularYukleniyor ? 'Hazırlanıyor...' : 'Testi Başlat',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _carkiCevir,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'Çarkı Çevir',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
} 