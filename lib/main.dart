import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_widget/home_widget.dart';
import 'core/theme.dart';
import 'providers/task_provider.dart';
import 'providers/pomodoro_provider.dart';
import 'services/notification_service.dart';
import 'services/ad_service.dart';
import 'services/telemetry_service.dart';
import 'services/remote_config_service.dart';
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

  // Record app open for telemetry
  try {
    await TelemetryService().recordAppOpen();
  } catch (e) {
    debugPrint('Error recording app open: $e');
  }

  // Load remote config (never blocks startup; falls back to cached/default)
  try {
    await RemoteConfigService.instance.load();
  } catch (e) {
    debugPrint('Error loading remote config: $e');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => PomodoroProvider()),
        // Expose RemoteConfigService for live re-theme on update
        ChangeNotifierProvider(
          create: (_) => RemoteConfigService.instance,
        ),
      ],
      child: const MitaApp(),
    ),
  );
}

class MitaApp extends StatelessWidget {
  const MitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild MaterialApp whenever remote config refreshes (live re-theme).
    return Consumer<RemoteConfigService>(
      builder: (context, rc, _) {
        return MaterialApp(
          title: 'Mita',
          theme: AppTheme.buildTheme(config: rc),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                    builder: (_) => const SplashScreen());
              case '/home':
                return MaterialPageRoute(
                    builder: (_) => const MainNavigation());
              case '/onboarding':
                return PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 600),
                  pageBuilder: (_, __, ___) => const OnboardingScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                );
              default:
                return MaterialPageRoute(
                    builder: (_) => const SplashScreen());
            }
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

