import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'auth_logo.dart';
import 'google_fonts.dart';
import '../main.dart' show themeProvider;
import 'student_onboarding/step_ui.dart';

/// Circular "next" chevron button used by the tutorial slideshows.
class CircleNextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const CircleNextButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).next,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedScale(
          scale: enabled ? 1.0 : 0.96,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? AppTheme.brandYellow
                  : isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppTheme.brandInk.withValues(alpha: 0.08),
              border: enabled
                  ? null
                  : Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppTheme.brandInk.withValues(alpha: 0.15),
                    ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: FaIcon(
                FontAwesomeIcons.arrowRight,
                size: 20,
                color: enabled
                    ? AppTheme.brandInk
                    : isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : AppTheme.brandInk.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen tutorial slideshow with a theme-aware gradient background,
/// top bar (back + logo + theme toggle), swipeable pages, animated page dots
/// and a circular chevron "next" control. The final page can replace the
/// chevron with a custom action via [actionBuilder].
class TutorialSlideshow extends StatefulWidget {
  final int pageCount;
  final Widget Function(int page) pageBuilder;
  final Widget? Function(int page, VoidCallback defaultNext)? actionBuilder;
  final VoidCallback onFinish;
  final VoidCallback? onBack;

  const TutorialSlideshow({
    super.key,
    required this.pageCount,
    required this.pageBuilder,
    required this.onFinish,
    this.actionBuilder,
    this.onBack,
  });

  @override
  State<TutorialSlideshow> createState() => _TutorialSlideshowState();
}

class _TutorialSlideshowState extends State<TutorialSlideshow> {
  late final PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= widget.pageCount) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentPage = page);
  }

  void _defaultNext() {
    if (_currentPage < widget.pageCount - 1) {
      _goToPage(_currentPage + 1);
    } else {
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final action = widget.actionBuilder?.call(_currentPage, _defaultNext);

    return Scaffold(
      body: Container(
        color: isDark ? AppTheme.brandDark : AppTheme.brandLight,
        child: SafeArea(
          child: Stack(
            children: [

              Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                    child: Row(
                      children: [
                        if (widget.onBack != null)
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : AppTheme.brandInk.withValues(alpha: 0.7),
                            ),
                            onPressed: widget.onBack,
                          )
                        else
                          const SizedBox(width: 52),
                        Expanded(
                          child: Center(
                            child: AuthLogo(height: 38),
                          ),
                        ),
                        Semantics(
                          label: AppLocalizations.of(context).toggleTheme,
                          child: IconButton(
                            icon: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : AppTheme.brandInk.withValues(alpha: 0.55),
                            ),
                            onPressed: () => themeProvider.toggleTheme(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slides
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.pageCount,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (p) => setState(() => _currentPage = p),
                      itemBuilder: (context, index) {
                        return KeyedSubtree(
                          key: ValueKey('slide-$index'),
                          child: StepReveal(
                            child: widget.pageBuilder(index),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom chrome: action + dots
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, bottomPadding + 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action != null)
                          action
                        else
                          CircleNextButton(
                            enabled: true,
                            onPressed: _defaultNext,
                          ),
                        const SizedBox(height: 18),
                        _PageDots(count: widget.pageCount, current: _currentPage),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: active
                ? AppTheme.brandYellow
                : isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.brandInk.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }
}

/// Centered content for a tutorial slide: illustration, title, subtitle, chips.
class TutorialSlide extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  final List<String>? chips;
  final double illustrationSizeFactor;

  const TutorialSlide({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.chips,
    this.illustrationSizeFactor = 0.36,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.brandInk;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationSize = (constraints.maxHeight * illustrationSizeFactor)
            .clamp(140.0, 210.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: illustrationSize * 1.15,
                height: illustrationSize,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: illustration,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.15,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
              if (chips != null) ...[
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: chips!.map((label) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppTheme.brandYellow.withValues(alpha: 0.08),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : AppTheme.brandYellow.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.solidStar,
                            size: 11,
                            color: AppTheme.brandAmber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppTheme.brandInk,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
