abstract class StorageInterface {
  Future<void> init();
  Future<void> saveDocument(String collection, Map<String, dynamic> data);
  Map<String, dynamic>? getDocument(String globalKey);
  List<Map<String, dynamic>> getCollection(String collection);
  Stream<dynamic> watchCollection(String collection);
  Future<void> clearAll();
}