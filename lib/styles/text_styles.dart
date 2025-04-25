import 'package:flutter/material.dart';

TextStyle textOnBaloonStyle = const TextStyle(
  color: Colors.white,
  fontSize: 25,
  fontWeight: FontWeight.bold,
  shadows: [
    Shadow(
      blurRadius: 3.0,
      color: Colors.black,
      offset: Offset(1.0, 1.0),
    ),
  ],
);

TextStyle buttonTextStyle = const TextStyle();

TextStyle onAnswerTextStyle(bool isCorrect) =>
    TextStyle(fontSize: 20, color: isCorrect ? Colors.green : Colors.red);
