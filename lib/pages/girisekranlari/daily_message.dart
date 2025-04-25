import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DailyMessagePage extends StatefulWidget {
  const DailyMessagePage({super.key});

  @override
  State<DailyMessagePage> createState() => _DailyMessagePageState();
}

class _DailyMessagePageState extends State<DailyMessagePage> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    // 1.5 saniye bekletiyoruz - daha kısa bir süre
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    // Ana sayfaya yönlendiriyoruz
    context.goNamed('homepage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/gunluk_mesaj.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
