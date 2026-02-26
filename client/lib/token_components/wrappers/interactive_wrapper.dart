import 'package:flutter/material.dart';
import '../../core_nucleus/action_queue/event_orchestrator.dart';


class InteractiveWrapper extends StatefulWidget {
  final Widget child;
  final Map<String, dynamic> events; 
  
  const InteractiveWrapper({
    super.key, 
    required this.child, 
    required this.events
  });

  @override
  State<InteractiveWrapper> createState() => _InteractiveWrapperState();
}

class _InteractiveWrapperState extends State<InteractiveWrapper> {
  
  void _handle(String trigger) {
    if (widget.events.containsKey(trigger)) {
      final actions = widget.events[trigger];
      if (actions is List) {
        EventOrchestrator.triggerChain(actions, context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.events.containsKey('on_tap') ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => _handle('on_hover_enter'),
      onExit: (_) => _handle('on_hover_exit'),
      child: GestureDetector(
        onTap: () => _handle('on_tap'),
        onLongPress: () => _handle('on_long_press'),
        onDoubleTap: () => _handle('on_double_tap'),
        child: widget.child,
      ),
    );
  }
}