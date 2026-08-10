import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'auth_logo.dart';
import 'auth_service.dart';
import 'glow_blob.dart';
import 'google_fonts.dart';
import 'hero_illustration.dart';
import '../main.dart' show themeProvider;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri?>? _linkSubscription;

  bool _isLoading = false;
  bool _isSendingEmailLink = false;
  bool _isHandlingEmailLink = false;
  bool _isGoogleSigningIn = false;
  bool _isResendingVerification = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _lastHandledEmailLink;
  String? _unverifiedEmail;

  @override
  void initState() {
    super.initState();
    _initializeEmailLinkHandling();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  Future<void> _initializeEmailLinkHandling() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleIncomingEmailLink(initialUri.toString());
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) async {
      await _handleIncomingEmailLink(uri.toString());
    });
  }

  Future<void> _handleIncomingEmailLink(String emailLink) async {
    if (_isHandlingEmailLink || _lastHandledEmailLink == emailLink) return;
    if (!_authService.isSignInWithEmailLink(emailLink)) return;

    _isHandlingEmailLink = true;
    _lastHandledEmailLink = emailLink;

    try {
      String? email = await _authService.getPendingEmailForLinkSignIn();

      if ((email == null || email.trim().isEmpty) && mounted) {
        email = await _promptForEmail();
      }

      if (email == null || email.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).pleaseEnterEmailToComplete)),
        );
        return;
      }

      await _authService.signInWithEmailLink(
        email: email,
        emailLink: emailLink,
      );
      await _authService.clearPendingEmailForLinkSignIn();

      if (!mounted) return;
      _emailController.text = email;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signedInWithEmailLink)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).emailLinkSignInFailed(e.toString()))),
      );
    } finally {
      _isHandlingEmailLink = false;
    }
  }

  Future<String?> _promptForEmail() {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.confirmYourEmail),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: l10n.emailExampleHint,
              labelText: l10n.labelEmail,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.continueAction),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEmailSignInLink() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() {
        _errorMessage = AppLocalizations.of(context).enterValidEmailForLink;
      });
      return;
    }

    setState(() {
      _isSendingEmailLink = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendSignInLinkToEmail(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signInLinkSent(email))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context).failedToSendSignInLink(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isSendingEmailLink = false);
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Check if email is verified
      final user = credential.user;
      if (user != null && !user.emailVerified) {
        // Re-send verification email so user gets another copy
        await user.sendEmailVerification();
        await _authService.signOut();
        if (!mounted) return;
        setState(() {
          _unverifiedEmail = _emailController.text.trim();
          _errorMessage = AppLocalizations.of(context)
              .emailNotVerified(_unverifiedEmail!);
        });
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).loginSuccessful)),
      );

      // Attempt backend authentication, but don't block login if unavailable
      final token = await _authService.getIdToken();
      if (token != null) {
        final backendResponse = await _authService.sendTokenToBackend(token);
        if (backendResponse == null) {
          debugPrint('Backend is not available — proceeding without backend session');
        } else {
          debugPrint('Backend response: $backendResponse');
        }
      }

      // Navigate to onboarding after successful login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendVerification() async {
    if (_unverifiedEmail == null) return;

    setState(() {
      _isResendingVerification = true;
      _errorMessage = null;
    });

    try {
      // Sign in briefly to send verification, then sign out
      final credential = await _authService.signIn(
        email: _unverifiedEmail!,
        password: _passwordController.text,
      );
      await credential.user!.sendEmailVerification();
      await _authService.signOut();

      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)
            .verificationResent(_unverifiedEmail!);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppLocalizations.of(context)
            .failedToResendVerification(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() => _isResendingVerification = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleSigningIn = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).googleSignInSuccessful)),
      );

      // Attempt backend authentication, but don't block login if unavailable
      final token = await _authService.getIdToken();
      if (token != null) {
        final backendResponse = await _authService.sendTokenToBackend(token);
        if (backendResponse == null) {
          debugPrint('Backend is not available — proceeding without backend session');
        } else {
          debugPrint('Backend response: $backendResponse');
        }
      }

      // Navigate to onboarding after successful login
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = scheme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F1115),
                    const Color(0xFF16203F),
                    const Color(0xFF0F1115),
                  ]
                : [
                    const Color(0xFFF7F9FC),
                    const Color(0xFFEAF1FF),
                    const Color(0xFFFFF3DC),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: GlowBlob(
                  color: AppTheme.brandGold.withValues(alpha: isDark ? 0.16 : 0.12),
                  size: 170,
                ),
              ),
              Positioned(
                bottom: 60,
                left: -60,
                child: GlowBlob(
                  color: AppTheme.brandBlue.withValues(alpha: isDark ? 0.2 : 0.1),
                  size: 200,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top bar: back (when pushed) + theme toggle
                        Row(
                          children: [
                            if (Navigator.canPop(context))
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : AppTheme.brandBlue.withValues(alpha: 0.7),
                                ),
                                onPressed: () => Navigator.pop(context),
                              )
                            else
                              const SizedBox(width: 48),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : AppTheme.brandBlue.withValues(alpha: 0.5),
                              ),
                              onPressed: () => themeProvider.toggleTheme(),
                            ),
                          ],
                        ),
                        // Hero illustration
                        Center(
                          child: HeroIllustration(
                            icon: FontAwesomeIcons.userGraduate,
                            orbitTopRight: FontAwesomeIcons.planeUp,
                            orbitBottomLeft: FontAwesomeIcons.lock,
                            size: 200,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: AuthLogo(height: 44),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.loginWelcomeBack,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.loginSubtitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isDark
                                ? const Color(0xFF232C3F).withValues(alpha: 0.95)
                                : Colors.white.withValues(alpha: 0.92),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : AppTheme.brandBlue.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : AppTheme.brandBlue.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: InputDecoration(
                                    labelText: l10n.labelEmail,
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.enterYourEmail;
                                    }
                                    if (!value.contains('@')) {
                                      return l10n.enterValidEmail;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: l10n.labelPassword,
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.enterYourPassword;
                                    }
                                    if (value.length < 6) {
                                      return l10n.passwordMinLength;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                if (_errorMessage != null)
                                  Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: scheme.error,
                                      height: 1.35,
                                    ),
                                  ),
                                if (_unverifiedEmail != null) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 44,
                                    child: OutlinedButton.icon(
                                      onPressed: _isResendingVerification
                                          ? null
                                          : _resendVerification,
                                      icon: _isResendingVerification
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            )
                                          : const Icon(Icons.refresh_outlined),
                                      label: Text(l10n.resendVerificationEmail),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: _isLoading ? 0 : 4,
                                      shadowColor: AppTheme.brandBlue.withValues(alpha: 0.4),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                l10n.logIn,
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(Icons.arrow_forward_rounded, size: 20),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: (_isSendingEmailLink || _isLoading || _isGoogleSigningIn)
                                        ? null
                                        : _sendEmailSignInLink,
                                    icon: _isSendingEmailLink
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.mark_email_read_outlined),
                                    label: Text(l10n.sendSignInLinkPasswordless),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        l10n.orContinueWith,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton.icon(
                                    onPressed: (_isGoogleSigningIn || _isLoading || _isSendingEmailLink)
                                        ? null
                                        : _signInWithGoogle,
                                    icon: _isGoogleSigningIn
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const _GoogleG(),
                                    label: Text(l10n.continueWithGoogle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/reset-password');
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: subtitleColor,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.dontHaveAccount,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: subtitleColor,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Text(
                                l10n.signUp,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.brandGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple Google "G" logo rendered in brand colors (no image dependency).
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
        ],
      ).createShader(rect),
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

