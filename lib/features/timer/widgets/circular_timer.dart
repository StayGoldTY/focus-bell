import 'dart:math';

import 'package:flutter/material.dart';

class CircularTimer extends StatelessWidget {
  final double progress;
  final String timeText;
  final String label;
  final String? subtitle;
  final double size;

  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeText,
    required this.label,
    this.subtitle,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strokeWidth = size < 170
        ? 8.0
        : size < 220
        ? 10.0
        : 12.0;
    final contentWidth = max(0.0, size - strokeWidth * 5);
    final timeFontSize = size < 150
        ? 28.0
        : size < 180
        ? 36.0
        : size < 220
        ? 46.0
        : 60.0;
    final labelFontSize = size < 150
        ? 12.0
        : size < 180
        ? 13.0
        : size < 220
        ? 15.0
        : 17.0;
    final subtitleFontSize = size < 220 ? 11.0 : 12.0;
    final timeLetterSpacing = size < 180 ? 1.0 : 2.0;
    final showSubtitle = subtitle != null && size >= 180;
    final labelSpacing = size < 180 ? 2.0 : 4.0;
    final subtitleSpacing = size < 220 ? 4.0 : 8.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              progressColor: theme.colorScheme.primary,
              strokeWidth: strokeWidth,
            ),
          ),
          SizedBox(
            width: contentWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    timeText,
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
                    label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: labelFontSize,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showSubtitle) ...[
                  SizedBox(height: subtitleSpacing),
                  Text(
                    subtitle!,
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
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    if (progress > 0.01 && progress < 0.99) {
      final endAngle = -pi / 2 + sweepAngle;
      final dotCenter = Offset(
        center.dx + radius * cos(endAngle),
        center.dy + radius * sin(endAngle),
      );

      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          max(4, strokeWidth * 0.6),
        );
      canvas.drawCircle(dotCenter, strokeWidth * 0.8, glowPaint);

      final dotPaint = Paint()..color = progressColor;
      canvas.drawCircle(dotCenter, strokeWidth / 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.backgroundColor != backgroundColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
