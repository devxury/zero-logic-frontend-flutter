import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../local_first_db/storage_core.dart';

class TelemetryWorker {
  static final TelemetryWorker _instance = TelemetryWorker._internal();
  factory TelemetryWorker() => _instance;
  TelemetryWorker._internal();

  final List<Map<String, dynamic>> _queue = [];

  void logCrash(String componentType, dynamic error, StackTrace stack) {
    final traceId = StorageCore().getDocument('sys_session')?['current_trace_id'] ?? 'unknown_trace';
    
    _queue.add({
      "trace_id": traceId,
      "status": "crash",
      "component_id": componentType,
      "error_stack": error.toString(),
      "platform": kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android')
    });

    _flushQueue();
  }

  Future<void> _flushQueue() async {
    if (_queue.isEmpty) return;

    try {
      final uri = Uri.parse('${Environment.httpBaseUrl}/v1/telemetry/batch');
      final payload = jsonEncode(_queue);

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _queue.clear();
        debugPrint("📡 [Telemetry] Batch enviado exitosamente.");
      }
    } catch (e) {
      debugPrint("[Telemetry] Fallo envío, reteniendo en cola...");
    }
  }
}