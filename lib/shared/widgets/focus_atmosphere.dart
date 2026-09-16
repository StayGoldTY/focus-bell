import 'package:flutter/material.dart';

class FocusAtmosphere extends StatelessWidget {
  final Widget child;

  const FocusAtmosphere({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Color.lerp(scheme.primary, const Color(0xFF121016), 0.82)!,
                  scheme.surface,
                  Color.lerp(scheme.tertiary, const Color(0xFF121016), 0.86)!,
                ]
              : [
                  Color.lerp(scheme.primaryContainer, Colors.white, 0.18)!,
                  scheme.surface,
                  Color.lerp(scheme.tertiaryContainer, scheme.surface, 0.35)!,
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.55),
                  radius: 0.85,
                  colors: [
                    scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
