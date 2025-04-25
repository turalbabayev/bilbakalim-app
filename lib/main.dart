import 'package:bilbakalim/firebase_notifications.dart';
import 'package:bilbakalim/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:bilbakalim/pages/homepage.dart';
import 'package:bilbakalim/pages/girisekranlari/loginpage.dart';
import 'package:bilbakalim/services/firebase_auth_services.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bilbakalim/navigation/main_navigation.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:bilbakalim/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bilbakalim/screens/launch_screen.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final _configuration = PurchasesConfiguration('appl_eNhvVMIKTHRSaBhJlmeTQmsMNuJ');

Future main() async {


  WidgetsFlutterBinding.ensureInitialized();

  await Purchases.configure(_configuration);

  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('Firebase başarıyla başlatıldı');
  } catch (e) {
    debugPrint('Firebase başlatma hatası: $e');
  }

  await initializeDateFormatting('tr_TR', null);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppTheme.primaryColor,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final notificationService = NotificationService();
  await notificationService.initialize();

  bool notificationStatus = await notificationService.getNotificationStatus();
  if (!notificationStatus) {
    await notificationService.requestPermission();
  }

  runApp(MyApp(firebaseInitialized: firebaseInitialized));
}

class MyApp extends StatefulWidget {
  final bool firebaseInitialized;

  const MyApp({required this.firebaseInitialized, super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseInitialized) {
      return const MaterialApp(
        home: LaunchScreen(),
      );
    }

    return MaterialApp(
      title: 'Bil Bakalım',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppTheme.primaryColor,
          secondary: AppTheme.secondaryColor,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: FutureBuilder(
        future: Future.delayed(const Duration(seconds: 2)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LaunchScreen();
          }

          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                return MainAppScaffold(firebaseInitialized: widget.firebaseInitialized);
              }

              return const LoginPage();
            },
          );
        },
      ),
    );
  }
}

class MainAppScaffold extends StatelessWidget {
  final bool firebaseInitialized;

  const MainAppScaffold({required this.firebaseInitialized, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: MainNavigation(firebaseInitialized: firebaseInitialized),
    );
  }
}
