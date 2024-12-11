import 'package:bilbakalim/styles/text_styles.dart';
import 'package:flutter/material.dart';

class BouncingImage extends StatefulWidget {
  final VoidCallback onTap;
  final String text;

  const BouncingImage({Key? key, required this.onTap, required this.text})
      : super(key: key);

  @override
  _BouncingImageState createState() => _BouncingImageState();
}

class _BouncingImageState extends State<BouncingImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap, // Tıklama işlemi burada yönlendirilir
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: Stack(alignment: Alignment.center, children: [
          Image.asset(
            'assets/images/baloon.png',
            width: 150,
            height: 150,
          ),
          SizedBox(
            width: 120,
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              style: textOnBaloonStyle,
            ),
          )
        ]),
      ),
    );
  }
}
