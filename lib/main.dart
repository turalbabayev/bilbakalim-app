import 'package:bilbakalim/router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BilBakalim());
}

class BilBakalim extends StatelessWidget {
  const BilBakalim({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Bil Bakalim',
      routerConfig: router,
    );
  }
}
