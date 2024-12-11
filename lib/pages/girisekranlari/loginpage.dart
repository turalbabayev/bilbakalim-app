import 'package:flutter/material.dart';
import 'package:bilbakalim/components/login_content.dart';
import 'package:bilbakalim/pages/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  double _backgroundHeight = 0;

  void _animateAndNavigate() {
    setState(() {
      _backgroundHeight = MediaQuery.of(context).size.height;
    });
    Future.delayed(Duration(milliseconds: 700), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Homepage()), // Yeni sayfa
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            width: MediaQuery.of(context).size.width,
            height: _backgroundHeight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/login_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: LoginContent(
              onLoginPressed: _animateAndNavigate,
            ),
          ),
        ],
      ),
    );
  }
}
