import 'package:bilbakalim/styles/background_decorations.dart';
import 'package:flutter/material.dart';

class DigerPage extends StatelessWidget {
  const DigerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Genel'),
      ),
      body: Container(
        decoration: pagesDecoration,
      ),
    );
  }
}
