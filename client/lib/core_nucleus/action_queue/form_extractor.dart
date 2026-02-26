import 'package:flutter/foundation.dart';
import '../../state_matrix/atomic_graph.dart';
import '../local_first_db/storage_core.dart';

class FormExtractor {
  
  static void extractAndSave({
    required String targetCollection,
    required List<dynamic> requiredKeys,
  }) {
    try {
      final Map<String, dynamic> payload = {};

      for (final key in requiredKeys) {
        final stringKey = key.toString();
        final value = AtomicGraph().getNode(stringKey).value;
        payload[stringKey] = value ?? ""; 
      }
      
      payload['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      payload['synced'] = false;

      StorageCore().saveDocument(targetCollection, payload);

    } catch (e) {
      debugPrint("🛑 [DeepCore Extractor] Fallo Crítico I/O: $e");
    }
  }
}