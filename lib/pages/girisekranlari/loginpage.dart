import 'package:flutter/material.dart';
import 'package:bilbakalim/components/login_content.dart';
import 'package:bilbakalim/components/register_content.dart';
import 'package:bilbakalim/pages/homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  double _backgroundHeight = 0;
  bool _isLogin = true;

  void _animateAndNavigate() {
    setState(() {
      _backgroundHeight = 0;
    });
    Future.delayed(Duration(milliseconds: 700), () {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => HomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    });
  }

  void _toggleContent() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            width: MediaQuery.of(context).size.width,
            height: _backgroundHeight == 0 ? screenHeight : _backgroundHeight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/login_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
              child: _isLogin
                  ? LoginContent(
                      onLoginPressed: _animateAndNavigate,
                    )
                  : RegisterContent(
                      onRegisterPressed: _animateAndNavigate,
                    )),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _toggleContent,
              child: Text(
                _isLogin ? "Register" : "Login",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
