import 'package:flutter/foundation.dart';

class HighFrequencyChannel<T> {
  final ValueNotifier<T> notifier;
  int _refCount = 0; 
  
  HighFrequencyChannel(T initialData) : notifier = ValueNotifier<T>(initialData);

  T get currentPayload => notifier.value;

  void retain() => _refCount++;
  
  bool release() {
    _refCount--;
    return _refCount <= 0;
  }

  void push(T newPayload) {
    notifier.value = newPayload; 
  }

  void dispose() {
    notifier.dispose();
  }
}

class BypassStreamEngine {
  static final BypassStreamEngine _instance = BypassStreamEngine._internal();
  factory BypassStreamEngine() => _instance;
  BypassStreamEngine._internal();

  final Map<String, HighFrequencyChannel<dynamic>> _channels = {};

  HighFrequencyChannel<T> subscribe<T>(String channelId, T initialData) {
    if (!_channels.containsKey(channelId)) {
      _channels[channelId] = HighFrequencyChannel<T>(initialData);
    }
    final channel = _channels[channelId] as HighFrequencyChannel<T>;
    channel.retain(); 
    return channel;
  }

  void unsubscribe(String channelId) {
    final channel = _channels[channelId];
    if (channel != null && channel.release()) {
      channel.dispose();
      _channels.remove(channelId);
    }
  }

  void emitFast(String channelId, dynamic data) {
    if (_channels.containsKey(channelId)) {
      _channels[channelId]!.push(data);
    }
  }
}