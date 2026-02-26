import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get fileName => '.env';

  static Future<void> init() async {
    await dotenv.load(fileName: fileName);
  }

  static String get _rawHost => dotenv.env['API_HOST'] ?? 'localhost:8080';


  static String get apiHost {
    if (kIsWeb) return _rawHost;
    
    if (Platform.isAndroid && _rawHost.startsWith('localhost')) {
      return _rawHost.replaceFirst('localhost', '10.0.2.2');
    }
    
    return _rawHost;
  }

  static String get httpBaseUrl => 'http://$apiHost';
  static String get wsBaseUrl => 'ws://$apiHost';
  
  static int get timeout => int.parse(dotenv.env['CONNECTION_TIMEOUT'] ?? '5000');
}