import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:objectbox/objectbox.dart';
import 'package:deep_core_frontend/objectbox.g.dart';
import 'entities.dart';
import 'storage_interface.dart';

class StorageAdapter implements StorageInterface {
  Store? _store;
  Box<DeepDocument>? _box;

  @override
  Future<void> init() async {
    if (_store != null) return;
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, "deep_core_db");
    
    if (!Directory(dbPath).existsSync()) {
       debugPrint("💾 [Native DB] Creando nueva instancia en: $dbPath");
    }

    _store = await openStore(directory: dbPath);
    _box = _store!.box<DeepDocument>();
    debugPrint("✅ [Native DB] ObjectBox Engine (C++) Online. Docs: ${_box!.count()}");
  }

  @override
  Future<void> saveDocument(String collection, Map<String, dynamic> data) async {
    if (_box == null) return;
    final String docId = data['id'] ?? data['uid'] ?? '${DateTime.now().millisecondsSinceEpoch}';
    final String globalKey = '$collection:$docId';

    final query = _box!.query(DeepDocument_.globalKey.equals(globalKey)).build();
    final existingDoc = query.findFirst();
    query.close();

    final docToSave = DeepDocument(
      id: existingDoc?.id ?? 0,
      globalKey: globalKey,
      collection: collection,
      payload: jsonEncode(data),
      updatedAt: DateTime.now(),
    );

    _box!.put(docToSave); 
  }

  @override
  Map<String, dynamic>? getDocument(String globalKey) {
    if (_box == null) return null;
    final query = _box!.query(DeepDocument_.globalKey.equals(globalKey)).build();
    final doc = query.findFirst();
    query.close();
    return doc != null ? jsonDecode(doc.payload) : null;
  }

  @override
  List<Map<String, dynamic>> getCollection(String collection) {
    if (_box == null) return [];
    final query = _box!.query(DeepDocument_.collection.equals(collection)).build();
    final docs = query.find();
    query.close();
    return docs.map((d) => jsonDecode(d.payload) as Map<String, dynamic>).toList();
  }

  @override
  Stream<dynamic> watchCollection(String collection) {
    if (_box == null) return const Stream.empty();
    return _box!.query(DeepDocument_.collection.equals(collection))
      .watch(triggerImmediately: true)
      .map((q) => q.find().map((d) => jsonDecode(d.payload)).toList());
  }

  @override
  Future<void> clearAll() async => _box?.removeAll();
}