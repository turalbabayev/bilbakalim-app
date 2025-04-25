import 'package:flutter/material.dart';

ButtonStyle bolumler_buttonStyles = ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  backgroundColor: Colors.blue.shade100,
  foregroundColor: Colors.black,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
);

ButtonStyle cikisyap_buttonStyle = ElevatedButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  textStyle: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
);

ButtonStyle girisYapButtonStyle = ButtonStyle(
  backgroundBuilder: (context, states, child) {
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.blue.shade100,
          Colors.blue.shade500,
          Colors.blue.shade900,
        ]),
      ),
      child: const Text(
        "Giriş yap",
        style: TextStyle(fontSize: 18, color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  },
);
