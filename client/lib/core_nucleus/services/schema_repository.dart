import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';
import '../logic/deep_kernel.dart';
import '../local_first_db/storage_core.dart';

class SchemaRepository {
  static final SchemaRepository _instance = SchemaRepository._internal();
  factory SchemaRepository() => _instance;
  SchemaRepository._internal();

  Future<void> bootEngine() async {
    try {
      final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
      final uri = Uri.parse('${Environment.httpBaseUrl}/v1/sync/boot?platform=$platform');

      final response = await http.get(uri).timeout(Duration(milliseconds: Environment.timeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final topology = data['topology'];

        await StorageCore().saveDocument('sys_cache', {'id': 'themes', 'data': topology['themes']});
        await StorageCore().saveDocument('sys_cache', {'id': 'layouts', 'data': topology['layouts']});
        await StorageCore().saveDocument('sys_cache', {'id': 'fragments', 'data': topology['fragments']});
        await StorageCore().saveDocument('sys_cache', {'id': 'manifests', 'data': topology['manifests']});
        
        debugPrint("[Boot] CMS Visual descargado y cacheado en Disco.");
      }
    } catch (e) {
      debugPrint("[Boot] Error de red. Fallback a Caché Local: $e");
    }
  }

  Future<Map<String, dynamic>> hydrateRoute(String path) async {
    try {
      final uri = Uri.parse('${Environment.httpBaseUrl}/v1/data/hydrate');
      final contextMap = DeepKernel().sessionContext.value;

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "path": path,
          "context": contextMap
        }),
      ).timeout(Duration(milliseconds: Environment.timeout));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      debugPrint("[Hydration] Fallo al obtener datos vivos: $e");
      return {};
    }
  }
}