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

    Future.delayed(
      const Duration(seconds: 3),
      () {
        context.pushReplacementNamed('homepage');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Image(
      image: AssetImage('assets/images/gunluk_mesaj.jpg'),
      fit: BoxFit.fill,
    );
  }
}
