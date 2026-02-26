import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/environment.dart';
import '../../state_matrix/atomic_graph.dart';
import '../logic/deep_kernel.dart';

class SyncOrchestrator {
  static final SyncOrchestrator _instance = SyncOrchestrator._internal();
  factory SyncOrchestrator() => _instance;
  SyncOrchestrator._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  void initialize() {
    if (_isConnected) return;

    try {
      final userId = DeepKernel().userId.value;
      final spaceId = userId.isNotEmpty ? userId : "guest_space";
      final uri = Uri.parse('${Environment.wsBaseUrl}/v1/sync?space_id=$spaceId');

      _channel = WebSocketChannel.connect(uri);
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          _handleIncomingSignal(message);
        },
        onError: (error) {
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      _isConnected = false;
    }
  }

  void _handleIncomingSignal(dynamic message) {
    try {
      final String raw = message.toString();
      final decoded = jsonDecode(raw);
      
      if (decoded['intent'] == 'CMD_REFRESH_TOPOLOGY') {
        DeepKernel().refreshTopology();
        return;
      }

      dynamic payload = decoded;
      
      if (decoded is Map && decoded.containsKey('Payload')) {
      }

      if (payload is Map && payload.containsKey('data')) {
         AtomicGraph().hydrate(payload['data']);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void sendForm(String collection, Map<String, dynamic> data, Map<String, dynamic>? extraData) {
    if (_channel == null) return;
    
    final payload = {
      "intent": "ACT_SUBMIT_FORM",
      "payload": {
        "collection": collection,
        "data": data,
        "extra_data": extraData ?? {}
      }
    };
    
    _channel!.sink.add(jsonEncode(payload));
  }

  void pushChange(String collection, Map<String, dynamic> data) {
    if (_channel == null) return;

    final event = {
      "collection": collection,
      "key": data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      "data": data
    };

    final payload = jsonEncode(event);
    _channel!.sink.add(payload);
  }

  void dispose() {
    _channel?.sink.close();
    _isConnected = false;
  }
}