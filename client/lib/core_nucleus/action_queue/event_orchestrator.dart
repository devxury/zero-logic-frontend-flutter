import 'package:flutter/material.dart';
import 'intent_dispatcher.dart';
import '../logic/deep_kernel.dart';
import '../../topology_layer/z_axis_matrix/overlay_orchestrator.dart';
import '../aot_compiler/theme_precompiler.dart';
import '../models/schema_definitions.dart';

class EventOrchestrator {
  
  static Future<void> triggerChain(List<dynamic>? actions, BuildContext context) async {
    if (actions == null || actions.isEmpty) return;

    for (final rawAction in actions) {
      if (rawAction is! Map<String, dynamic>) continue;
      
      final String type = rawAction['type'] ?? 'noop';
      final Map<String, dynamic> payload = rawAction['payload'] ?? {};
      final int delay = rawAction['delay'] ?? 0;

      if (delay > 0) await Future.delayed(Duration(milliseconds: delay));

      await _executeAtom(type, payload, context);
    }
  }

  static Future<void> _executeAtom(String type, Map<String, dynamic> payload, BuildContext ctx) async {
    try {
      switch (type) {
        case 'net.http_request':
          await IntentDispatcher().dispatch('ACT_LOGIN_HTTP', payload); 
          break;
          
        case 'data.submit_form':
          await IntentDispatcher().dispatch('ACT_SUBMIT_FORM', payload);
          break;

        case 'nav.overlay_open':
           if (payload['component'] != null) {
             final spec = ComponentSpec.fromMap(payload['component']);
             final compiled = AOTCompiler.compileComponent(spec);
             OverlayOrchestrator().injectOverlay(payload['id'] ?? 'modal', compiled);
           }
           break;
           
        case 'nav.overlay_close':
           OverlayOrchestrator().removeOverlay(payload['id'] ?? 'modal');
           break;

        case 'store.set_context':
           final String? key = payload['key'];
           final dynamic value = payload['value'];
           if (key != null) {
             DeepKernel().updateContextAttribute(key, value);
           }
           break;
           
        case 'store.set_variable':
           final String? key = payload['key'];
           if (key != null) {
             DeepKernel().mutateState(key, payload['value']);
           }
           break;

        case 'auth.logout':
           DeepKernel().logout();
           break;

        case 'ui.console_log':
           debugPrint("🖨️ [BACKEND LOG]: ${payload['message']}");
           break;
           
        case 'ui.toast':
           ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(payload['message'] ?? '')));
           break;

        default:
           await IntentDispatcher().dispatch(type, payload);
           break;
      }
    } catch (e) {
      debugPrint("🛑 [EventOrchestrator] Fallo en acción '$type': $e");
    }
  }
}