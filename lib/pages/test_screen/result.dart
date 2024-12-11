import 'package:flutter/material.dart';

class TestCompletionScreen extends StatelessWidget {
  int correct;
  int uncorrect;
  TestCompletionScreen(
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
