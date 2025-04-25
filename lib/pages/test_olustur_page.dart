import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/scheduler.dart';
import 'package:bilbakalim/pages/bolumler/test_screen/exam_question_screen.dart';

class TestOlusturPage extends StatefulWidget {
  const TestOlusturPage({super.key});

  @override
  State<TestOlusturPage> createState() => _TestOlusturPageState();
}

class _TestOlusturPageState extends State<TestOlusturPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Seçili konular ve alt konular
  final Set<String> _secilenKonular = {};
  final Set<String> _secilenAltKonular = {};
  
  // Konular ve alt konular listesi
  List<Map<String, dynamic>> _konular = [];
  Map<String, List<Map<String, dynamic>>> _altKonular = {};
  
  // Durum değişkenleri
  bool _yukleniyor = true;
  bool _testOlusturuluyor = false;
  int _soruSayisi = 10;
  int _maxSoruSayisi = 10;
  int _testSuresi = 30; // Varsayılan 30 dakika
  List<Map<String, dynamic>>? _secilenSorular;

  @override
  void initState() {
    super.initState();
    _konulariGetir();
  }

  // Konuları getir
  Future<void> _konulariGetir() async {
    try {
      setState(() => _yukleniyor = true);
      
      final snapshot = await _firestore.collection('konular').get();
      
      setState(() {
        _konular = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        _yukleniyor = false;
      });
    } catch (e) {
      print('Konular getirilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konular yüklenirken bir hata oluştu')),
      );
      setState(() => _yukleniyor = false);
    }
  }

  // Maksimum soru sayısını güncelle
  Future<void> _maxSoruSayisiniGuncelle() async {
    try {
      int toplamSoru = 0;
      
      for (var konuId in _secilenKonular) {
        for (var altKonu in _altKonular[konuId] ?? []) {
          if (!_secilenAltKonular.contains(altKonu['id'])) continue;
          
          final sorularSnapshot = await _firestore
              .collection('konular')
              .doc(konuId)
              .collection('altkonular')
              .doc(altKonu['id'])
              .collection('sorular')
              .get();
          
          toplamSoru += sorularSnapshot.docs.length;
        }
      }
      
      setState(() {
        _maxSoruSayisi = toplamSoru;
        if (_soruSayisi > _maxSoruSayisi) {
          _soruSayisi = _maxSoruSayisi;
        }
      });
    } catch (e) {
      print('Maksimum soru sayısı güncellenirken hata: $e');
    }
  }

  // Alt konuları getir
  Future<void> _altKonulariGetir(String konuId) async {
    try {
      if (_altKonular.containsKey(konuId)) return;
      
      final snapshot = await _firestore
          .collection('konular')
          .doc(konuId)
          .collection('altkonular')
          .get();
      
      setState(() {
        _altKonular[konuId] = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
      });
    } catch (e) {
      print('Alt konular getirilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alt konular yüklenirken bir hata oluştu')),
      );
    }
  }

  // Test oluştur
  Future<void> _testOlustur() async {
    if (_secilenKonular.isEmpty || _secilenAltKonular.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir konu ve alt konu seçin')),
      );
      return;
    }

    try {
      setState(() => _testOlusturuluyor = true);
      
      List<Map<String, dynamic>> tumSorular = [];
      
      // Seçili alt konulardan soruları getir
      for (var konuId in _secilenKonular) {
        for (var altKonu in _altKonular[konuId] ?? []) {
          if (!_secilenAltKonular.contains(altKonu['id'])) continue;
          
          final sorularSnapshot = await _firestore
              .collection('konular')
              .doc(konuId)
              .collection('altkonular')
              .doc(altKonu['id'])
              .collection('sorular')
              .get();
          
          tumSorular.addAll(sorularSnapshot.docs.map((doc) => {
            'id': doc.id,
            'konuId': konuId,
            'altKonuId': altKonu['id'],
            ...doc.data(),
          }));
        }
      }
      
      if (tumSorular.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seçili konularda soru bulunamadı')),
        );
        setState(() => _testOlusturuluyor = false);
        return;
      }

      // Soruları karıştır ve istenen sayıda soru seç
      tumSorular.shuffle();
      _secilenSorular = tumSorular.take(_soruSayisi).toList();
      
      // Testi başlat
      if (!mounted) return;
      setState(() => _testOlusturuluyor = false);
      
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamQuestionScreen(
            sorular: _secilenSorular!,
            testSuresi: _testSuresi,
          ),
        ),
      );
    } catch (e) {
      print('Test oluşturulurken hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test oluşturulurken bir hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _testOlusturuluyor = false);
      }
    }
  }

  // Konu seçim dialogu
  Future<void> _konuSecimDialogu() async {
    Set<String> tempSecilenKonular = Set.from(_secilenKonular);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Konuları Seçin',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _konular.map((konu) {
              return CheckboxListTile(
                title: Text(
                  konu['baslik'] ?? '',
                  style: GoogleFonts.poppins(),
                ),
                value: tempSecilenKonular.contains(konu['id']),
                onChanged: (bool? value) {
                  if (value == true) {
                    tempSecilenKonular.add(konu['id']);
                  } else {
                    tempSecilenKonular.remove(konu['id']);
                  }
                  (context as Element).markNeedsBuild();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _secilenKonular.clear();
                _secilenKonular.addAll(tempSecilenKonular);
                _secilenAltKonular.clear();
              });
              for (var konuId in _secilenKonular) {
                await _altKonulariGetir(konuId);
              }
              await _maxSoruSayisiniGuncelle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Tamam',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Alt konu seçim dialogu
  Future<void> _altKonuSecimDialogu() async {
    if (_secilenKonular.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce konu seçmelisiniz')),
      );
      return;
    }

    Set<String> tempSecilenAltKonular = Set.from(_secilenAltKonular);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Alt Konuları Seçin',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _secilenKonular.expand((konuId) {
              final altKonular = _altKonular[konuId] ?? [];
              return altKonular.map((altKonu) {
                return CheckboxListTile(
                  title: Text(
                    altKonu['baslik'] ?? '',
                    style: GoogleFonts.poppins(),
                  ),
                  value: tempSecilenAltKonular.contains(altKonu['id']),
                  onChanged: (bool? value) {
                    if (value == true) {
                      tempSecilenAltKonular.add(altKonu['id']);
                    } else {
                      tempSecilenAltKonular.remove(altKonu['id']);
                    }
                    (context as Element).markNeedsBuild();
                  },
                );
              });
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _secilenAltKonular.clear();
                _secilenAltKonular.addAll(tempSecilenAltKonular);
              });
              Navigator.pop(context);
              await _maxSoruSayisiniGuncelle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(
              'Tamam',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Stack(
      children: [
        // Arkaplan
        Positioned.fill(
          child: Container(
            color: const Color(0xFFF8F9FA),
          ),
        ),
        
        // İçerik
        Positioned.fill(
          top: statusBarHeight + 56,
          child: _yukleniyor
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Konu Seçimi
                      Text(
                        'Konular',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _konuSecimDialogu,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _secilenKonular.isEmpty
                                        ? 'Konu seçin'
                                        : '${_secilenKonular.length} konu seçildi',
                                    style: GoogleFonts.poppins(
                                      color: _secilenKonular.isEmpty
                                          ? Colors.grey[600]
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Alt Konu Seçimi
                      Text(
                        'Alt Konular',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _altKonuSecimDialogu,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _secilenAltKonular.isEmpty
                                        ? 'Alt konu seçin'
                                        : '${_secilenAltKonular.length} alt konu seçildi',
                                    style: GoogleFonts.poppins(
                                      color: _secilenAltKonular.isEmpty
                                          ? Colors.grey[600]
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Soru Sayısı
                      Text(
                        'Soru Sayısı',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_soruSayisi > 5) {
                                  setState(() => _soruSayisi--);
                                }
                              },
                              icon: Icon(
                                Icons.remove,
                                color: _soruSayisi > 5
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _soruSayisi.toString(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_soruSayisi < _maxSoruSayisi) {
                                  setState(() => _soruSayisi++);
                                }
                              },
                              icon: Icon(
                                Icons.add,
                                color: _soruSayisi < _maxSoruSayisi
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Test Süresi
                      Text(
                        'Test Süresi (Dakika)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_testSuresi > 5) {
                                  setState(() => _testSuresi -= 5);
                                }
                              },
                              icon: Icon(
                                Icons.remove,
                                color: _testSuresi > 5
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '$_testSuresi',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_testSuresi < 120) {
                                  setState(() => _testSuresi += 5);
                                }
                              },
                              icon: Icon(
                                Icons.add,
                                color: _testSuresi < 120
                                    ? AppTheme.primaryColor
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Test Oluştur Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _testOlusturuluyor ? null : _testOlustur,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _testOlusturuluyor
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Testi Başlat',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
                  color: AppTheme.primaryColor,
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
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Test Oluştur',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
} 