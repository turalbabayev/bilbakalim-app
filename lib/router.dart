// import 'package:bilbakalim/pages/bolumler/graphics.dart';
import 'package:bilbakalim/pages/girisekranlari/loginpage.dart';
import 'package:bilbakalim/pages/girisekranlari/daily_message.dart';
import 'package:bilbakalim/pages/diger/diger.dart';
import 'package:bilbakalim/pages/homepage.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

final router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return '/homepage';
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
      path: '/homepage',
      name: 'homepage',
      builder: (context, state) {
        bool isFirebaseInitialized = false;
        try {
          isFirebaseInitialized = Firebase.app().name.isNotEmpty;
        } catch (e) {
          isFirebaseInitialized = false;
        }
        return HomePage(firebaseInitialized: isFirebaseInitialized);
      },
      routes: [
        GoRoute(
          path: 'diger',
          name: 'diger',
          builder: (context, state) => DigerPage(),
        ),
        // GoRoute(
        //   path: 'graphics',
        //   name: 'graphics',
        //   builder: (context, state) => GraphicsPage(),
        // )
      ],
    )
  ],
);
