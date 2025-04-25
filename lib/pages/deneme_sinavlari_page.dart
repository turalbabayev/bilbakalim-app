import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:bilbakalim/data/deneme_sinavlari.dart';

class DenemeSinavlariPage extends StatefulWidget {
  const DenemeSinavlariPage({super.key});

  @override
  State<DenemeSinavlariPage> createState() => _DenemeSinavlariPageState();
}

class _DenemeSinavlariPageState extends State<DenemeSinavlariPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> denemeler = [];

  @override
  void initState() {
    super.initState();
    _denemeleriGetir();
  }

  Future<void> _denemeleriGetir() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      denemeler = [];
    });

    try {
      print('Denemeler yükleniyor...');
      final denemeler = await DenemeSinaviOlusturucu.denemeleriOlustur();
      
      if (!mounted) return;

      if (denemeler.isEmpty) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Henüz soru bankasında yeterli soru bulunmamaktadır. Lütfen daha sonra tekrar deneyiniz.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      setState(() {
        this.denemeler = denemeler.map((deneme) => deneme.toMap()).toList();
        isLoading = false;
      });
      
      print('${denemeler.length} deneme başarıyla yüklendi');
      
    } catch (e) {
      print('Hata: $e');
      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Denemeler yüklenirken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyiniz.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _denemeDetayiniGoster(Map<String, dynamic> deneme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF686EDD), Color(0xFF8B91FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        deneme['baslik'],
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deneme['aciklama'],
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoChip(Icons.timer, '${deneme['sureDakika']} dakika'),
                      const SizedBox(width: 12),
                      _infoChip(Icons.quiz, '${deneme['soruSayisi']} soru'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konu Dağılımı',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(deneme['konuDagilimi'] as Map<String, int>).entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF686EDD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${entry.value} soru',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF686EDD),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Deneme sınavını başlat
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF686EDD),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Denemeyi Başlat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF686EDD).withOpacity(0.1),
                    Colors.white,
                  ],
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
                  decoration: const BoxDecoration(
                    color: Color(0xFF686EDD),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
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
                        'Deneme Sınavları',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
            top: statusBarHeight + 76,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : denemeler.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz deneme sınavı bulunmamaktadır',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: denemeler.length,
                        itemBuilder: (context, index) {
                          final deneme = denemeler[index];
                          return GestureDetector(
                            onTap: () => _denemeDetayiniGoster(deneme),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF686EDD), Color(0xFF8B91FF)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF686EDD).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -20,
                                    bottom: -20,
                                    child: Icon(
                                      Icons.quiz_rounded,
                                      size: 100,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deneme['baslik'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          deneme['aciklama'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            _infoChip(
                                              Icons.timer,
                                              '${deneme['sureDakika']} dakika',
                                            ),
                                            const SizedBox(width: 12),
                                            _infoChip(
                                              Icons.quiz,
                                              '${deneme['soruSayisi']} soru',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 