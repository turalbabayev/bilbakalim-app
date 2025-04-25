import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BouncingImage extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const BouncingImage({
    Key? key,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BouncingImage> createState() => _BouncingImageState();
}

class _BouncingImageState extends State<BouncingImage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Konuya uygun ikon seçimi (renk değiştirilmeden)
    IconData iconData = Icons.book_outlined;
    
    // Konu başlığına göre ikonları belirleme
    String title = widget.text.toLowerCase();
    if (title.contains('türkçe') || title.contains('dil') || title.contains('dilbilgisi')) {
      iconData = Icons.book_outlined;
    } else if (title.contains('matematik') || title.contains('sayılar') || title.contains('geometri')) {
      iconData = Icons.calculate;
    } else if (title.contains('fen') || title.contains('bilim')) {
      iconData = Icons.science;
    } else if (title.contains('tarih') || title.contains('uygarlık') || title.contains('devrim')) {
      iconData = Icons.history_edu;
    } else if (title.contains('coğrafya') || title.contains('harita') || title.contains('iklim')) {
      iconData = Icons.map;
    } else if (title.contains('ekonomi') || title.contains('para') || title.contains('finans')) {
      iconData = Icons.attach_money;
    } else if (title.contains('hukuk') || title.contains('adalet') || title.contains('kanun')) {
      iconData = Icons.gavel;
    } else if (title.contains('edebiyat') || title.contains('şiir') || title.contains('roman')) {
      iconData = Icons.menu_book;
    } else if (title.contains('ingilizce') || title.contains('yabancı')) {
      iconData = Icons.translate;
    } else if (title.contains('din') || title.contains('islam') || title.contains('kuran')) {
      iconData = Icons.brightness_3;
    } else if (title.contains('sosyal') || title.contains('toplum')) {
      iconData = Icons.groups;
    } else if (title.contains('felsefe') || title.contains('düşünce')) {
      iconData = Icons.psychology;
    } else if (title.contains('kimya') || title.contains('element')) {
      iconData = Icons.science;
    } else if (title.contains('fizik') || title.contains('mekanik') || title.contains('enerji')) {
      iconData = Icons.tungsten;
    } else if (title.contains('biyoloji') || title.contains('canlı') || title.contains('hücre')) {
      iconData = Icons.biotech;
    }
    
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        iconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Başla',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DotsPainter extends CustomPainter {
  final Color color;

  DotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double dotSize = 3;
    const double spacing = 20;

    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
