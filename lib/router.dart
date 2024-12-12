import 'package:bilbakalim/pages/daily_message.dart';
import 'package:bilbakalim/pages/diger.dart';
import 'package:bilbakalim/pages/girisekranlari/loginpage.dart';
import 'package:bilbakalim/pages/homepage.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'main',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dailyMessage',
      name: 'dailyMessage',
      builder: (context, state) => const DailyMessagePage(),
    ),
    GoRoute(
      path: '/homepage',
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
