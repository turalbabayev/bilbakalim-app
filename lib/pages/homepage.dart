// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:bilbakalim/components/flying_baloon.dart';
import 'package:bilbakalim/pages/bolumler/genel_bankacilik.dart';
import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  void goPage(Widget page, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

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
        )),
        child: GridView.builder(
          itemCount: 7,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
          ),
          itemBuilder: (context, index) {
            return BouncingImage(
              onTap: () {
                goPage(const GenelBankacilik(), context);
              },
            );
          },
        ),
      ),
    );
  }
}
