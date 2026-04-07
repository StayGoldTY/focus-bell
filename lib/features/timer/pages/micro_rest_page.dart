import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/sound_data.dart';
import '../../../shared/services/storage_service.dart';
import '../models/timer_state.dart';
import '../providers/timer_provider.dart';

class MicroRestOverlay extends ConsumerStatefulWidget {
  const MicroRestOverlay({super.key});

  @override
  ConsumerState<MicroRestOverlay> createState() => _MicroRestOverlayState();
}

class _MicroRestOverlayState extends ConsumerState<MicroRestOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final String _tip;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _tip = scienceTips[Random().nextInt(scienceTips.length)];
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(timerProvider);
    final showTips = ref.read(storageServiceProvider).showScienceTips;

    if (timerState.phase != TimerPhase.microRest) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // 呼吸脉冲圆环
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + _pulseController.value * 0.15;
                final opacity = 0.4 + _pulseController.value * 0.6;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: opacity),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary
                              .withValues(alpha: opacity * 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${timerState.remainingSeconds}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // 提示文字
            Text(
              '闭上眼睛 · 深呼吸',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
              ),
            ).animate().fadeIn(duration: 800.ms),

            const Spacer(),

            // 科学小贴士
            if (showTips)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _tip,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 20),

            // 底部进度条
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: timerState.progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }
}
