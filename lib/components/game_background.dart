import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math' show Random;

class GameBackground extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final bool showParticles;

  const GameBackground({
    Key? key,
    required this.child,
    this.primaryColor = const Color(0xFF6B4EFF),
    this.secondaryColor = const Color(0xFF8A70FF),
    this.accentColor = const Color(0xFFB39DFF),
    this.showParticles = true,
  }) : super(key: key);

  @override
  State<GameBackground> createState() => _GameBackgroundState();
}

class _GameBackgroundState extends State<GameBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final int _particleCount = 50;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Parçacıkları oluştur
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(Particle(
        position: Offset(
          _random.nextDouble() * 400,
          _random.nextDouble() * 800,
        ),
        size: _random.nextDouble() * 15 + 5,
        speed: _random.nextDouble() * 0.8 + 0.2,
        color: _random.nextBool() 
            ? widget.primaryColor.withOpacity(0.4) 
            : widget.secondaryColor.withOpacity(0.4),
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.02,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ana gradient arkaplan
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.primaryColor.withOpacity(0.2),
                widget.secondaryColor.withOpacity(0.3),
                widget.accentColor.withOpacity(0.4),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Animasyonlu parçacıklar
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Parçacıkları hareket ettir
              for (var particle in _particles) {
                particle.position = Offset(
                  particle.position.dx + particle.speed * math.cos(particle.rotation),
                  particle.position.dy + particle.speed * math.sin(particle.rotation),
                );
                
                particle.rotation += particle.rotationSpeed;
                
                // Ekran dışına çıkan parçacıkları yeniden konumlandır
                if (particle.position.dx > MediaQuery.of(context).size.width + 50) {
                  particle.position = Offset(
                    -50,
                    _random.nextDouble() * MediaQuery.of(context).size.height,
                  );
                }
                
                if (particle.position.dy > MediaQuery.of(context).size.height + 50) {
                  particle.position = Offset(
                    _random.nextDouble() * MediaQuery.of(context).size.width,
                    -50,
                  );
                }
              }
              
              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                painter: ParticlePainter(particles: _particles),
              );
            },
          ),
        
        // Dekoratif şekiller
        Positioned(
          top: -100,
          right: -100,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: widget.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        Positioned(
          bottom: -150,
          left: -100,
          child: Transform.rotate(
            angle: -math.pi / 6,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: widget.secondaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: widget.secondaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Ana içerik
        widget.child,
      ],
    );
  }
}

class Particle {
  Offset position;
  final double size;
  final double speed;
  final Color color;
  double rotation;
  final double rotationSpeed;

  Particle({
    required this.position,
    required this.size,
    required this.speed,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;
      
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      
      // Yıldız şekli çiz
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final angle = (i * 4 * math.pi / 5) - math.pi / 2;
        final point = Offset(
          math.cos(angle) * particle.size,
          math.sin(angle) * particle.size,
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
} 