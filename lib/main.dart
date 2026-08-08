import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/app_theme.dart';
import 'widgets/counsellor_dashboard_page.dart';
import 'widgets/login_page.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/signup_page.dart';
import 'widgets/reset_password_page.dart';
import 'widgets/student_dashboard_page.dart';
import 'widgets/student_onboarding/student_onboarding_page.dart';
import 'widgets/theme_provider.dart';
import 'widgets/welcome_page.dart';

final ThemeProvider themeProvider = ThemeProvider();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  runApp(OrientaaApp(initialRoute: hasSeenWelcome ? '/login' : '/welcome'));
}

class OrientaaApp extends StatefulWidget {
  final String initialRoute;

  const OrientaaApp({super.key, required this.initialRoute});

  @override
  State<OrientaaApp> createState() => _OrientaaAppState();
}

class _OrientaaAppState extends State<OrientaaApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orientaa',
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      initialRoute: widget.initialRoute,
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/student-onboarding': (_) => const StudentOnboardingPage(),
        '/student-dashboard': (_) => const StudentDashboardPage(),
        '/counsellor-dashboard': (_) => const CounsellorDashboardPage(),
        '/signup': (_) => const SignupPage(),
        '/reset-password': (_) => const ResetPasswordPage(),
      },
    );
  }
}
