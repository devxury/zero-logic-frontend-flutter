import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../logic/deep_kernel.dart';
import '../../topology_layer/z_axis_matrix/overlay_orchestrator.dart';
import '../../topology_layer/nested_router.dart'; 
import '../../state_matrix/atomic_graph.dart';
import '../models/schema_definitions.dart'; 
import '../aot_compiler/theme_precompiler.dart';
import '../local_first_db/storage_core.dart';

class IntentDispatcher {
  static final IntentDispatcher _instance = IntentDispatcher._internal();
  factory IntentDispatcher() => _instance;
  IntentDispatcher._internal();

  Future<void> dispatch(String? action, [dynamic payload]) async {
    if (action == null || action.isEmpty) return;
    
    final kernel = DeepKernel();
    final schema = kernel.activeSchema.value;

    try {
      switch (action) {

        case 'nav.overlay_open':
           if (payload != null && payload['component'] != null) {
             final spec = ComponentSpec.fromMap(payload['component']);
             final compiled = AOTCompiler.compileComponent(spec);
             
             OverlayOrchestrator().injectOverlay(payload['id'] ?? 'modal', compiled);
           }
           break;
           
        case 'nav.overlay_close':
           OverlayOrchestrator().removeOverlay(payload['id'] ?? 'modal');
           break;

        case 'ACT_NAVIGATE_SLOT':
          final mapPayload = payload as Map<String, dynamic>?;
          final String? targetId = mapPayload?['target_id'];
          final String regionId = mapPayload?['region_id'] ?? 'main'; 
          if (targetId != null) {
            NestedRouter().navigateSlot(regionId: regionId, targetId: targetId);
          }
          break;


        case 'net.http_request': 
        case 'ACT_LOGIN_HTTP':  
          final mapPayload = payload as Map<String, dynamic>;
          final String urlPath = mapPayload['url'];
          
          final Map<String, dynamic> body = {};

          if (mapPayload.containsKey('body') && mapPayload['body'] is Map) {
             final staticBody = mapPayload['body'] as Map<String, dynamic>;
             staticBody.forEach((k, v) {

                body[k] = v; 
             });
          }

          final Map<String, dynamic> fieldMapping = mapPayload['field_mapping'] ?? {};
          fieldMapping.forEach((apiKey, graphKey) {
            final String val = AtomicGraph().getNode(graphKey.toString()).value?.toString() ?? '';
            body[apiKey] = val;
          });

          debugPrint("🚀 [HTTP] POST $urlPath | Payload: $body");

          try {
            final uri = Uri.parse('${Environment.httpBaseUrl}$urlPath');
            final response = await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            );

            if (response.statusCode >= 200 && response.statusCode < 300) {
              final respData = jsonDecode(response.body);
              
              if (respData is Map && respData['token'] != null) {
                await StorageCore().saveDocument('sys_session_token', {'token': respData['token']});
                final String user = respData['user_id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
                final Map<String, dynamic> ctx = respData['context'] ?? {'scope': 'authenticated'};
                kernel.setSession(user, ctx);
              }

              if (respData is List) {

                for (var actionItem in respData) {
                   dispatch(actionItem['type'], actionItem['payload']);
                }
              }
            } else {
              debugPrint("🛑 Error HTTP: ${response.statusCode} - ${response.body}");
            }
          } catch (e) {
            debugPrint("🛑 Error Crítico de Red: $e");
          }
          break;


        case 'ACT_LOGOUT':
        case 'auth.logout':
          kernel.logout();
          break;

        case 'ui.toast':

           debugPrint("🔔 TOAST: ${payload['message']}");
           break;


        case 'store.set_variable':
           final String? key = payload['key'];
           if (key != null) kernel.mutateState(key, payload['value']);
           break;

        default:
          debugPrint("⚠️ Unknown Action: $action");
      }
    } catch (e, stack) {
      debugPrint("🛑 Dispatch Error [$action]: $e");
      debugPrint(stack.toString());
    }
  }
}