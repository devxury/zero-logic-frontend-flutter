import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core_nucleus/models/schema_definitions.dart';
import '../../core_nucleus/services/component_registry.dart';
import '../../token_components/motion/spring_physics_engine.dart';
import '../../core_nucleus/logic/deep_kernel.dart';
import '../../core_nucleus/utils/token_resolver.dart';

class OverlayOrchestrator {
  static final OverlayOrchestrator _instance = OverlayOrchestrator._internal();
  factory OverlayOrchestrator() => _instance;
  OverlayOrchestrator._internal();

  final activeOverlays = signal<Map<String, ComponentSpec>>({});

  void injectOverlay(String id, ComponentSpec component) {
    final copy = Map<String, ComponentSpec>.from(activeOverlays.value);
    copy[id] = component;
    activeOverlays.value = copy;
  }

  void removeOverlay(String id) {
    final copy = Map<String, ComponentSpec>.from(activeOverlays.value);
    copy.remove(id);
    activeOverlays.value = copy;
  }
}

class ZAxisMatrixLayer extends StatelessWidget {
  final Widget child;
  const ZAxisMatrixLayer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final overlays = OverlayOrchestrator().activeOverlays.value;
      final schema = DeepKernel().activeSchema.value;

      final String backdropMotion = TokenResolver.resolveValue(schema.globalProps['overlay_motion'])?.toString() ?? 'fade_in';
      final int backdropDuration = int.tryParse(TokenResolver.resolveValue(schema.globalProps['overlay_motion_duration'])?.toString() ?? '200') ?? 200;
      
      final Color backdropColor = TokenResolver.resolveColor(schema.globalProps['overlay_backdrop_color']) ?? Colors.black54;

      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          
          if (overlays.isNotEmpty)
            TokenMotion(
              props: {'motion': backdropMotion, 'motion_duration': backdropDuration},
              child: GestureDetector(
                onTap: () {
                  final lastKey = overlays.keys.last;
                  OverlayOrchestrator().removeOverlay(lastKey);
                },
                child: Container(
                  color: backdropColor,
                  child: Material(
                    color: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: overlays.entries.map((entry) {
                        return GestureDetector(
                          onTap: () {}, 
                          child: ComponentRegistry.build(entry.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            )
        ],
      );
    });
  }
}