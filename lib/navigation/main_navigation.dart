import 'package:flutter/material.dart';
import 'package:bilbakalim/styles/app_theme.dart';
import 'package:bilbakalim/pages/homepage.dart';
import 'package:bilbakalim/pages/ders_page.dart';
import 'package:bilbakalim/pages/ayarlar_page.dart';
import 'package:bilbakalim/pages/sorular_page.dart';
import 'package:bilbakalim/pages/oyunlar_page.dart';
import 'package:bilbakalim/services/fetch_titles.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class MainNavigation extends StatefulWidget {
  final bool firebaseInitialized;
  
  const MainNavigation({
    Key? key,
    required this.firebaseInitialized,
  }) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HomePage(firebaseInitialized: widget.firebaseInitialized),
          const DersPage(firebaseInitialized: true),
          const SorularPage(),
          const OyunlarPage(),
          const AyarlarPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 4,
              activeColor: Colors.white,
              iconSize: 22,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: AppTheme.primaryColor,
              color: Colors.grey[600],
              tabs: const [
                GButton(
                  icon: Icons.home_rounded,
                  text: 'Ana Sayfa',
                ),
                GButton(
                  icon: Icons.school_rounded,
                  text: 'Dersler',
                ),
                GButton(
                  icon: Icons.quiz_rounded,
                  text: 'Sorular',
                ),
                GButton(
                  icon: Icons.games_rounded,
                  text: 'Oyunlar',
                ),
                GButton(
                  icon: Icons.settings_rounded,
                  text: 'Ayarlar',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.jumpToPage(index);
                });
              },
            ),
          ),
        ),
      ),
    );
  }
} 