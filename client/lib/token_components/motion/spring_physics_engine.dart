import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core_nucleus/utils/token_resolver.dart';

class TokenMotion extends StatelessWidget {
  final Widget child;
  final Map<String, dynamic> props;

  const TokenMotion({super.key, required this.child, required this.props});

  @override
  Widget build(BuildContext context) {
    final String? motionType = TokenResolver.resolveValue(props['motion'])?.toString();
    
    if (motionType == null || motionType.isEmpty) return child;

    final int durationMs = int.tryParse(TokenResolver.resolveValue(props['motion_duration'])?.toString() ?? '400') ?? 400;
    final int delayMs = int.tryParse(TokenResolver.resolveValue(props['motion_delay'])?.toString() ?? '0') ?? 0;

    final duration = Duration(milliseconds: durationMs);
    final delay = Duration(milliseconds: delayMs);

    const bouncyCurve = Curves.easeOutBack; 
    const smoothCurve = Curves.easeOutQuart;

    switch (motionType) {
      case 'spring_up':
        return child.animate(delay: delay)
          .fadeIn(duration: duration, curve: smoothCurve)
          .slideY(begin: 0.2, end: 0, duration: duration, curve: bouncyCurve);
          
      case 'slide_in_right':
        return child.animate(delay: delay)
          .fadeIn(duration: duration, curve: smoothCurve)
          .slideX(begin: 0.1, end: 0, duration: duration, curve: smoothCurve);
          
      case 'scale_bouncy':
        return child.animate(delay: delay)
          .fadeIn(duration: duration, curve: smoothCurve)
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: duration, curve: bouncyCurve);
          
      case 'fade_in':
        return child.animate(delay: delay)
          .fadeIn(duration: duration, curve: Curves.easeIn);
          
      default:
        return child;
    }
  }
}