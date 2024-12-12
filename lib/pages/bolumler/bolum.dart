import 'package:bilbakalim/pages/test_screen/question_screen.dart';
import 'package:bilbakalim/styles/background_decorations.dart';
import 'package:bilbakalim/styles/button_styles.dart';
import 'package:flutter/material.dart';

class BolumPage extends StatelessWidget {
  String appBarTitle;
  BolumPage({super.key, required this.appBarTitle});

  final List<String> _bolumler = [
    "Bankacılık tarihi",
    "Bankaların sınıflandırılması",
    "Finansal piyasalar",
    "Nakit değerler ",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(appBarTitle),
        elevation: 0,
      ),
      body: Container(
        decoration: pagesDecoration,
        child: Center(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemCount: _bolumler.length,
            itemBuilder: (context, index) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: ElevatedButton(
                    style: bolumler_buttonStyles,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return QuestionPage();
                        },
                      ));
                    },
                    child: Text(
                      _bolumler[index],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
