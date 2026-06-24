import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_update/in_app_update.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  static final GlobalKey<MainNavigationState> _key = GlobalKey<MainNavigationState>();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          InAppUpdate.startFlexibleUpdate().then((_) {
            InAppUpdate.completeFlexibleUpdate();
          });
        }
      }
    } catch (e) {
      debugPrint('[InAppUpdate] Error checking for update: $e');
    }
  }

  static GlobalKey<MainNavigationState> get navigatorKey => _key;

  void goToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppTheme.surface, width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            backgroundColor: AppTheme.background,
            selectedItemColor: AppTheme.accent,
            unselectedItemColor: AppTheme.mutedText,
            selectedLabelStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.radio_button_checked),
                label: 'Today',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
