import 'package:bilbakalim/pages/girisekranlari/loginpage.dart';
import 'package:bilbakalim/pages/daily_message.dart';
import 'package:bilbakalim/pages/diger.dart';
import 'package:bilbakalim/pages/homepage.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null && state.uri.toString() != '/login') {
      return '/login';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dailyMessage',
      name: 'dailyMessage',
      builder: (context, state) => const DailyMessagePage(),
    ),
    GoRoute(
      path: '/',
      name: 'homepage',
      builder: (context, state) => HomePage(),
      routes: [
        GoRoute(
          path: 'diger',
          name: 'diger',
          builder: (context, state) => const DigerPage(),
        )
      ],
    )
  ],
);
