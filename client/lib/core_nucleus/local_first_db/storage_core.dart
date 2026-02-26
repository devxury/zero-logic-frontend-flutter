import 'dart:async';
import 'package:flutter/foundation.dart';

import 'storage_interface.dart';
import 'storage_impl_web.dart' if (dart.library.io) 'storage_impl_native.dart';

import 'sync_orchestrator.dart'; 

class StorageCore {
  static final StorageCore _instance = StorageCore._internal();
  factory StorageCore() => _instance;
  StorageCore._internal();

  final StorageInterface _adapter = StorageAdapter();

  Future<void> init() async {
    debugPrint("🔋 [StorageCore] Inicializando motor de persistencia...");
    await _adapter.init();
    
    SyncOrchestrator().initialize(); 
  }

  Future<void> saveDocument(String collection, Map<String, dynamic> data) async {
    await _adapter.saveDocument(collection, data);
    
    SyncOrchestrator().pushChange(collection, data);
  }

  Map<String, dynamic>? getDocument(String globalKey) {
    return _adapter.getDocument(globalKey);
  }

  List<Map<String, dynamic>> getCollection(String collection) {
    return _adapter.getCollection(collection);
  }

  Stream<dynamic> watch(String collection) {
    return _adapter.watchCollection(collection);
  }

  Future<void> nukeDatabase() async {
    await _adapter.clearAll();
    debugPrint("☢️ [StorageCore] Base de datos formateada.");
  }
}