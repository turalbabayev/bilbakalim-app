// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:bilbakalim/components/flying_baloon.dart';
import 'package:bilbakalim/pages/bolumler/bolum.dart';
import 'package:bilbakalim/pages/diger.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  void goPage(Widget page, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  final List<String> _bolumler = [
    "Bankacılık",
    "Ekonomi",
    "Hukuk",
    "Krediler",
    "Muhasebe",
    "Genel kültür",
    "Önemli Terimler",
    "Diğer",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/background.png"),
            fit: BoxFit.fill,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.05), BlendMode.darken),
          ),
        ),
        child: GridView.builder(
          itemCount: _bolumler.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
          ),
          itemBuilder: (context, index) {
            String title = _bolumler[index];
            return BouncingImage(
              text: title,
              onTap: () {
                if (index != 7)
                  goPage(BolumPage(appBarTitle: title), context);
                else
                  goPage(DigerPage(), context);
              },
            );
          },
        ),
      ),
    );
  }
}
