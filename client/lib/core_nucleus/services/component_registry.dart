import 'package:flutter/material.dart';
import '../models/schema_definitions.dart';
import '../../token_components/wrappers/interactive_wrapper.dart';
import 'telemetry_worker.dart';

typedef ComponentBuilder = Widget Function(Map<String, dynamic> props);

class ComponentRegistry {
  static final Map<String, ComponentBuilder> _registry = {};

  static void register(String type, ComponentBuilder builder) {
    _registry[type] = builder;
  }

  static Widget build(ComponentSpec spec) {
    final builder = _registry[spec.type];

    if (builder == null) {
      TelemetryWorker().logCrash(spec.type, "Missing Component in Registry", StackTrace.current);
      return const SizedBox.shrink(); 
    }
    
    try {
      Widget builtWidget = builder(spec.props);

      final dynamic eventsRaw = spec.props['events'];
      if (eventsRaw is Map<String, dynamic> && eventsRaw.isNotEmpty) {
        return InteractiveWrapper(
          events: eventsRaw,
          child: builtWidget,
        );
      }

      return builtWidget;
      
    } catch (e, stack) {
      TelemetryWorker().logCrash(spec.type, e, stack);
      
      return Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
           color: Colors.red.withOpacity(0.1),
           border: Border.all(color: Colors.red),
         ),
         child: Text("Error UI: ${spec.type}", style: const TextStyle(color: Colors.red, fontSize: 10)),
      );
    }
  }
}