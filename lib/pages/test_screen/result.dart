import 'package:flutter/material.dart';

class TestCompletionPage extends StatelessWidget {
  final int correct;
  final int uncorrect;
  const TestCompletionPage(
      {super.key, required this.correct, required this.uncorrect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Testi Tamamladınız!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("Doğru cevap sayınız : ${correct.toString()}"),
            Text("Yanlış cevap sayınız : ${uncorrect.toString()}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Ana Sayfaya Dön"),
            ),
          ],
        ),
      ),
    );
  }
}
