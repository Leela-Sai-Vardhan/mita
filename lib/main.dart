import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Home Widget (optional - for widget support)
  try {
    HomeWidget.setAppGroupId('group.com.dreamstarx.mita');
  } catch (e) {
    debugPrint('HomeWidget app group error: $e');
  }
  
  // Initialize Notification Service
  try {
    await NotificationService().initialize();
  } catch (e, stack) {
    debugPrint('Error initializing notifications: $e\n$stack');
  }

  // Initialize Ad Service
  try {
    await AdService().initialize();
  } catch (e, stack) {
    debugPrint('Error initializing ads: $e\n$stack');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
      ],
      child: const MitaApp(),
    ),
  );
}

class MitaApp extends StatelessWidget {
  const MitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mita',
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const MainNavigation());
          case '/onboarding':
            return PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 600),
              pageBuilder: (_, __, ___) => const OnboardingScreen(),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

