import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../google_fonts.dart';

/// Wraps a child with a short fade + slide-in reveal on first build.
/// Supports staggered delays and honors reduced-motion accessibility.
class StepReveal extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const StepReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }
    final totalMs = (duration + delay).inMilliseconds;
    final delayMs = delay.inMilliseconds;
    final durationMs = duration.inMilliseconds;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final progress = ((value * totalMs - delayMs) / durationMs)
            .clamp(0.0, 1.0)
            .toDouble();
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Premium gradient hero header shown at the top of each onboarding step.
class StepHeroCard extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final List<String>? chips;
  final Widget? trailing;

  const StepHeroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.chips,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.brandInk;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.brandLightOutline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.brandYellow,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(child: FaIcon(icon, color: AppTheme.brandInk, size: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                    height: 1.35,
                  ),
                ),
                if (chips != null && chips!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips!.map((label) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppTheme.brandYellow.withValues(alpha: 0.1),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppTheme.brandYellow.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(
                              FontAwesomeIcons.solidCircleCheck,
                              size: 11,
                              color: isDark
                                  ? AppTheme.brandGold
                                  : AppTheme.brandAmber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.8)
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
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Section heading with a small brand icon.
class StepSectionLabel extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final String? badge;
  final String? helper;

  const StepSectionLabel({
    super.key,
    required this.icon,
    required this.label,
    this.badge,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : AppTheme.brandInk.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.brandYellow.withValues(alpha: 0.18),
              ),
              child: FaIcon(icon, size: 12, color: AppTheme.brandYellow),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.brandInk,
                letterSpacing: 0.2,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.brandGold.withValues(alpha: 0.15),
                ),
                child: Text(
                  badge!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.brandGold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              helper!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-width rounded primary CTA with press feedback, loading + disabled states.
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final FaIconData? icon;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null && !widget.loading;
    final bg = widget.backgroundColor ?? AppTheme.brandBlue;

    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTapDown: enabled ? (_) => _scaleController.forward() : null,
            onTapUp: enabled
                ? (_) {
                    _scaleController.reverse();
                    widget.onPressed!();
                  }
                : null,
            onTapCancel: enabled ? () => _scaleController.reverse() : null,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: enabled
                    ? bg
                    : isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : bg.withValues(alpha: 0.08),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: widget.loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: enabled ? AppTheme.brandInk : scheme.onSurface,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: enabled
                                  ? AppTheme.brandInk
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : bg.withValues(alpha: 0.35),
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (widget.icon != null) ...[
                            const SizedBox(width: 9),
                            FaIcon(
                              widget.icon,
                              size: 15,
                              color: enabled
                                  ? AppTheme.brandInk
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : bg.withValues(alpha: 0.35),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined secondary action (e.g. Back) with press feedback.
class SecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final FaIconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onPressed != null;

    return ScaleTransition(
      scale: _scale,
      child: SizedBox(
        height: 56,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTapDown: enabled ? (_) => _scaleController.forward() : null,
            onTapUp: enabled
                ? (_) {
                    _scaleController.reverse();
                    widget.onPressed!();
                  }
                : null,
            onTapCancel: enabled ? () => _scaleController.reverse() : null,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppTheme.brandYellow.withValues(alpha: 0.35),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      FaIcon(
                        widget.icon,
                        size: 14,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.brandInk.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppTheme.brandInk.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Always-visible pinned bottom navigation bar for onboarding steps.
///
/// Replaces the "button at the bottom of a long scroll view" pattern so the
/// primary CTA is never hidden below the fold. Theme-aware (light/dark) with
/// safe-area padding, optional Back button, validation hint, and extra row
/// (e.g. a Skip link).
class StepNavBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool nextEnabled;
  final FaIconData? nextIcon;
  final String? hint;
  final Widget? extra;
  final bool loading;

  const StepNavBar({
    super.key,
    this.onBack,
    required this.onNext,
    required this.nextLabel,
    required this.nextEnabled,
    this.nextIcon = FontAwesomeIcons.arrowRight,
    this.hint,
    this.extra,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The parent onboarding scaffold already wraps content in SafeArea, so a
    // fixed bottom padding keeps the bar tight without double-inset spacing.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.brandSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.brandLightOutline,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hint != null && !nextEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 12,
                color: isDark
                    ? AppTheme.brandYellow
                    : AppTheme.brandAmber,
              ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      hint!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.brandYellow
                            : AppTheme.brandAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            children: [
              if (onBack != null) ...[
                SecondaryButton(
                  label: AppLocalizations.of(context).back,
                  onPressed: onBack,
                  icon: FontAwesomeIcons.arrowLeft,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: PrimaryButton(
                  label: nextLabel,
                  onPressed: nextEnabled ? onNext : null,
                  icon: nextIcon,
                  loading: loading,
                ),
              ),
            ],
          ),
          if (extra != null) ...[const SizedBox(height: 4), extra!],
        ],
      ),
    );
  }
}

/// Themed icon-prefixed text field with floating label.
class BrandTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String initialText;
  final String hint;
  final String label;
  final FaIconData prefixIcon;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final int maxLines;

  const BrandTextField({
    super.key,
    this.controller,
    this.initialText = '',
    required this.hint,
    required this.label,
    required this.prefixIcon,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<BrandTextField> createState() => _BrandTextFieldState();
}

class _BrandTextFieldState extends State<BrandTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialText);
    if (widget.controller != null) {
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : AppTheme.brandInk,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : AppTheme.brandInk.withValues(alpha: 0.4),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : AppTheme.brandInk.withValues(alpha: 0.7),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: FaIcon(
            widget.prefixIcon,
            size: 16,
            color: isDark
                ? Colors.white.withValues(alpha: 0.55)
                : AppTheme.brandInk.withValues(alpha: 0.6),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : scheme.outline.withValues(alpha: 0.55),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : scheme.outline.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
