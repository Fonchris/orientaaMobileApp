import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'widgets/app_shell.dart';
import 'widgets/app_theme.dart';
import 'widgets/counselors/screens/counselor_onboarding_page.dart';
import 'widgets/counselors/services/push_notifications.dart';
import 'widgets/google_fonts.dart';
import 'widgets/locale_provider.dart';
import 'widgets/login_page.dart';
import 'widgets/onboarding_page.dart';
import 'widgets/reset_password_page.dart';
import 'widgets/signup_page.dart';
import 'widgets/student_onboarding/student_onboarding_page.dart';
import 'widgets/theme_provider.dart';
import 'widgets/welcome_page.dart';

final ThemeProvider themeProvider = ThemeProvider();
final LocaleProvider localeProvider = LocaleProvider();

/// Lets the FCM handler show in-app SnackBars without a BuildContext.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  await Future.wait([themeProvider.load(), localeProvider.load()]);

  PushNotifications.instance.onForeground = (data) {
    final messenger = appNavigatorKey.currentState?.context;
    if (messenger == null) return;
    final title = data['title'] as String?;
    final body = data['body'] as String?;
    if (title == null || body == null) return;
    ScaffoldMessenger.of(messenger).showSnackBar(
      SnackBar(
        content: Text('$title\n$body', maxLines: 2, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 4),
      ),
    );
  };
  await PushNotifications.instance.init();

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
    themeProvider.addListener(_onChanged);
    localeProvider.addListener(_onChanged);
    _syncFontFamily();
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onChanged);
    localeProvider.removeListener(_onChanged);
    super.dispose();
  }

  /// Uses the bundled Cairo font for Arabic (covers Arabic + Latin glyphs);
  /// keeps the system font elsewhere so nothing else changes.
  void _syncFontFamily() {
    final code = localeProvider.locale.languageCode;
    GoogleFonts.setFontFamily(code == 'ar' ? 'Cairo' : 'sans-serif');
  }

  void _onChanged() {
    _syncFontFamily();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Orientaa',
      navigatorKey: appNavigatorKey,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: widget.initialRoute,
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/onboarding': (_) => const OnboardingPage(),
        '/student-onboarding': (_) => const StudentOnboardingPage(),
        '/counselor-onboarding': (_) => CounselorOnboardingPage(
          counselorUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
        '/student-dashboard': (_) => const AppShell(),
        '/counsellor-dashboard': (_) => const AppShell(),
        '/signup': (_) => const SignupPage(),
        '/reset-password': (_) => const ResetPasswordPage(),
      },
    );
  }
}
