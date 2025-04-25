import 'package:bilbakalim/pages/bolumler/test_screen/result.dart';
import 'package:bilbakalim/styles/text_styles.dart';
import 'package:bilbakalim/components/html_content_viewer.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class ExamQuestionScreen extends StatefulWidget {
  final List<Map<String, dynamic>> sorular;
  final int testSuresi;

  const ExamQuestionScreen({
    super.key,
    required this.sorular,
    required this.testSuresi,
  });

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  final PageController _pageController = PageController();
  final ScrollController _gridController = ScrollController();
  
  int _currentQuestionIndex = 0;
  Map<int, String?> _cevaplar = {};
  Map<int, bool> _isaretlenenler = {};
  
  // Süre ile ilgili değişkenler
  late Timer _timer;
  late Duration _kalanSure;
  bool _sinavBitti = false;
  
  @override
  void initState() {
    super.initState();
    _kalanSure = Duration(minutes: widget.testSuresi);
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_kalanSure.inSeconds > 0) {
          _kalanSure = _kalanSure - const Duration(seconds: 1);
        } else {
          _timer.cancel();
          _sinaviBitir();
        }
      });
    });
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${hours == "00" ? "" : "$hours:"}$minutes:$seconds";
  }
  
  void _cevapVer(String cevap) {
    setState(() {
      _cevaplar[_currentQuestionIndex] = cevap;
    });
  }
  
  void _soruIsaretle() {
    setState(() {
      _isaretlenenler[_currentQuestionIndex] = !(_isaretlenenler[_currentQuestionIndex] ?? false);
    });
  }
  
  void _sinaviBitir() {
    if (!mounted) return;
    
    _timer.cancel();
    setState(() => _sinavBitti = true);
    
    // Sonuçları hesapla
    int dogru = 0;
    int yanlis = 0;
    int bos = 0;
    
    for (int i = 0; i < widget.sorular.length; i++) {
      if (_cevaplar[i] == null) {
        bos++;
      } else if (_cevaplar[i] == widget.sorular[i]['dogruCevap']) {
        dogru++;
      } else {
        yanlis++;
      }
    }
    
    // Sonuç sayfasına git
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestCompletionPage(
          correct: dogru,
          uncorrect: yanlis,
          konuIndex: '',
          altkonuIndex: '',
          elapsedTime: _formatDuration(Duration(minutes: widget.testSuresi) - _kalanSure),
          totalQuestions: widget.sorular.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog();
        return false;
      },
      child: Scaffold(
        body: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
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
              child: Column(
                children: [
                  // Üst Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Geri Butonu
                      GestureDetector(
                        onTap: _showExitConfirmationDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Süre
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_kalanSure),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sınavı Bitir
                      GestureDetector(
                        onTap: () => _showFinishConfirmationDialog(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.done_all,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Soru Grid'i
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      controller: _gridController,
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.sorular.length,
                      itemBuilder: (context, index) {
                        final bool isAnswered = _cevaplar.containsKey(index);
                        final bool isMarked = _isaretlenenler[index] ?? false;
                        final bool isCurrent = index == _currentQuestionIndex;
                        
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? Colors.white
                                  : isAnswered
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMarked ? Colors.yellow : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrent
                                      ? AppTheme.primaryColor
                                      : Colors.white,
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
            
            // Sorular
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentQuestionIndex = index);
                  // Scroll grid to show current question
                  _gridController.animateTo(
                    index * 48.0, // 40 width + 8 margin
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                itemCount: widget.sorular.length,
                itemBuilder: (context, index) {
                  final soru = widget.sorular[index];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Soru Kartı
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Soru Metni
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: HtmlContentViewer(
                                  htmlContent: soru['soruMetni'],
                                  textColor: AppTheme.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              // İşaretleme Butonu
                              Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey[200]!,
                                    ),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _soruIsaretle,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isaretlenenler[index] ?? false
                                                ? Icons.flag
                                                : Icons.flag_outlined,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isaretlenenler[index] ?? false
                                                ? 'İşareti Kaldır'
                                                : 'Soruyu İşaretle',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.orange,
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
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Cevap Seçenekleri
                        ...soru['cevaplar'].map<Widget>((cevap) {
                          final optionValue = cevap;
                          final isSelected = _cevaplar[index] == optionValue;
                          final optionIndex = soru['cevaplar'].indexOf(cevap);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _cevapVer(optionValue),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryColor.withOpacity(0.1)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.grey[300]!,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor
                                              : Colors.grey[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            String.fromCharCode(65 + (optionIndex as int)),
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: HtmlContentViewer(
                                          htmlContent: optionValue,
                                          textColor: isSelected
                                              ? AppTheme.primaryColor
                                              : AppTheme.textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        
                        const SizedBox(height: 20),
                        
                        // Navigasyon Butonları
                        Row(
                          children: [
                            if (index > 0)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[200],
                                    foregroundColor: Colors.grey[800],
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.arrow_back, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Önceki Soru',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (index > 0 && index < widget.sorular.length - 1)
                              const SizedBox(width: 12),
                            if (index < widget.sorular.length - 1)
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sonraki Soru',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Sınavdan Çıkmak İstiyor musun?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'Sınavdan çıkarsan tüm cevapların silinecek ve süren sıfırlanacak.',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Sınava Devam Et',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sınavdan Çık',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            const Icon(
              Icons.help_outline_rounded,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Sınavı Bitirmek İstiyor musun?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kalan Süre: ${_formatDuration(_kalanSure)}',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tüm soruları cevapladığından emin misin?',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Sınava Devam Et',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await Future.delayed(const Duration(milliseconds: 100));
              if (!mounted) return;
              Navigator.pop(context);
              _sinaviBitir();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sınavı Bitir',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 