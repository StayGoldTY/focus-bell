import 'dart:math';

import 'package:flutter/material.dart';

class CircularTimer extends StatefulWidget {
  final double progress;
  final String timeText;
  final String label;
  final String? subtitle;
  final double size;
  final bool pulse;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeText,
    required this.label,
    this.subtitle,
    this.size = 280,
    this.pulse = false,
  });

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.pulse) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size;
    final strokeWidth = size < 170
        ? 8.0
        : size < 220
        ? 10.0
        : 13.0;
    final contentWidth = max(0.0, size - strokeWidth * 5);
    final timeFontSize = size < 150
        ? 28.0
        : size < 180
        ? 36.0
        : size < 220
        ? 46.0
        : 58.0;
    final labelFontSize = size < 150
        ? 12.0
        : size < 180
        ? 13.0
        : size < 220
        ? 15.0
        : 16.0;
    final subtitleFontSize = size < 220 ? 11.0 : 12.0;
    final timeLetterSpacing = size < 180 ? 1.0 : 2.0;
    final showSubtitle = widget.subtitle != null && size >= 180;
    final labelSpacing = size < 180 ? 2.0 : 6.0;
    final subtitleSpacing = size < 220 ? 4.0 : 8.0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.pulse ? 0.35 + _pulse.value * 0.45 : 0.55;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.88,
                height: size * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: glow * 0.16),
                      theme.colorScheme.surface.withValues(alpha: 0.55),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(
                        alpha: glow * 0.22,
                      ),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: widget.progress,
                  backgroundColor: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.45,
                  ),
                  progressColor: theme.colorScheme.primary,
                  accentColor: theme.colorScheme.tertiary,
                  strokeWidth: strokeWidth,
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: SizedBox(
        width: contentWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.timeText,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: timeFontSize,
                  fontWeight: FontWeight.w300,
                  color: theme.colorScheme.onSurface,
                  height: 1,
                  letterSpacing: timeLetterSpacing,
                ),
              ),
            ),
            SizedBox(height: labelSpacing),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: labelFontSize,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            if (showSubtitle) ...[
              SizedBox(height: subtitleSpacing),
              Text(
                widget.subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: subtitleFontSize,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final Color accentColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final haloPaint = Paint()
      ..color = progressColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 8;
    canvas.drawCircle(center, radius, haloPaint);

    final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
    if (sweepAngle <= 0) {
      return;
    }

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [
          progressColor.withValues(alpha: 0.55),
          progressColor,
          accentColor,
        ],
        stops: const [0.0, 0.72, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);

    if (progress > 0.01 && progress < 0.99) {
      final endAngle = -pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * cos(endAngle),
        center.dy + radius * sin(endAngle),
      );

      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          max(4, strokeWidth * 0.6),
        );
      canvas.drawCircle(dotCenter, strokeWidth * 0.9, glowPaint);

      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(dotCenter, strokeWidth / 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.backgroundColor != backgroundColor ||
      old.progressColor != progressColor ||
      old.accentColor != accentColor ||
      old.strokeWidth != strokeWidth;
}
