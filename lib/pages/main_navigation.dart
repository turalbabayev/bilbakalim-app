import 'package:flutter/material.dart';
import 'package:bilbakalim/pages/homepage.dart';

class MainNavigation extends StatelessWidget {
  final bool firebaseInitialized;
  
  const MainNavigation({required this.firebaseInitialized, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HomePage(firebaseInitialized: firebaseInitialized);
  }
} 