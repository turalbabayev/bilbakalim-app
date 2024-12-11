import 'dart:convert';
import 'package:bilbakalim/pages/test_screen/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart'; // Konfeti için gerekli

class QuestionScreen extends StatefulWidget {
  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int correct = 0;
  int notcorrect = 0;
  String? _selectedAnswer;
  bool _isCorrect = false;
  bool _isAnswered = false;
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    String jsonString =
        await rootBundle.loadString('assets/sorular/ornek_sorular.json');
    final jsonData = json.decode(jsonString);
    setState(() {
      _questions = jsonData['questions'];
    });
  }

  void _checkAnswer(String selectedOption) {
    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedOption;
      _isCorrect =
          _questions[_currentQuestionIndex]['answer'] == selectedOption;

      if (_isCorrect) {
        _confettiController.play();
        correct += 1;
      } else {
        notcorrect += 1;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _confettiController.stop();
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
        _isCorrect = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TestCompletionScreen(correct: correct, uncorrect: notcorrect),
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Soru ${_currentQuestionIndex + 1}'),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
      ),
      body: Stack(
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentQuestion['question'],
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...currentQuestion['options'].entries.map<Widget>((entry) {
                  final optionKey = entry.key;
                  final optionValue = entry.value;
                  final isCorrectAnswer =
                      currentQuestion['answer'] == optionKey;

                  return ListTile(
                    title: Text(optionValue),
                    leading: Radio<String>(
                      value: optionKey,
                      groupValue: _selectedAnswer,
                      onChanged: _isAnswered
                          ? null
                          : (value) {
                              _checkAnswer(optionKey);
                            },
                    ),
                    trailing: _isAnswered &&
                            isCorrectAnswer &&
                            _selectedAnswer != optionKey
                        ? const Icon(Icons.pets, color: Colors.green)
                        : null,
                    tileColor: _isAnswered && _selectedAnswer == optionKey
                        ? (_isCorrect ? Colors.green : Colors.red)
                        : null,
                  );
                }),
                const Spacer(),
                _isAnswered
                    ? ElevatedButton(
                        onPressed: _isAnswered ? _nextQuestion : null,
                        child: Text(
                          _currentQuestionIndex < _questions.length - 1
                              ? "Diğer Soruya Geç"
                              : "Testi Bitir",
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
