import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'storage_interface.dart';

class StorageAdapter implements StorageInterface {
  late Box _webBox;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _webBox = await Hive.openBox('deep_core_web_storage');
    debugPrint("✅ [Web DB] Hive Engine Online.");
  }

  @override
  Future<void> saveDocument(String collection, Map<String, dynamic> data) async {
    if (!_webBox.isOpen) await init();
    final String docId = data['id'] ?? data['uid'] ?? '${DateTime.now().millisecondsSinceEpoch}';
    final String globalKey = '$collection:$docId';
    
    final payload = { 'collection': collection, 'data': data };
    await _webBox.put(globalKey, jsonEncode(payload));
  }

  @override
  Map<String, dynamic>? getDocument(String globalKey) {
    final raw = _webBox.get(globalKey);
    return raw != null ? jsonDecode(raw)['data'] : null;
  }

  @override
  List<Map<String, dynamic>> getCollection(String collection) {
    final List<Map<String, dynamic>> results = [];
    for (var i = 0; i < _webBox.length; i++) {
      final raw = _webBox.getAt(i);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded['collection'] == collection) results.add(decoded['data']);
      }
    }
    return results;
  }

  @override
  Stream<dynamic> watchCollection(String collection) {
    return _webBox.watch().map((_) => getCollection(collection));
  }

  @override
  Future<void> clearAll() async => await _webBox.clear();
}