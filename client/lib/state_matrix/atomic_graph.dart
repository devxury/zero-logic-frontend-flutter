import 'package:signals/signals.dart';

/// GRAFO ATÓMICO O(1)
class AtomicGraph {
  static final AtomicGraph _instance = AtomicGraph._internal();
  factory AtomicGraph() => _instance;
  AtomicGraph._internal();

  final Map<String, Signal<dynamic>> _nodes = {};

  Signal<dynamic> getNode(String key, {dynamic fallback}) {
    return _nodes.putIfAbsent(key, () => signal<dynamic>(fallback));
  }

  void mutate(String key, dynamic value) {
    getNode(key).value = value;
  }

void hydrate(Map<String, dynamic> payload) {
    payload.forEach((key, value) {
      final cleanKey = key.startsWith('\$') ? key.substring(1) : key;
      getNode(cleanKey).value = value;
    });
  }

  Map<String, dynamic> get snapshot {
    return _nodes.map((key, sig) => MapEntry(key, sig.value));
  }
}