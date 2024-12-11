import 'package:bilbakalim/pages/homepage.dart';
import 'package:bilbakalim/pages/girisekranlari/loginpage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BilBakalim());
}

class BilBakalim extends StatelessWidget {
  const BilBakalim({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
