import 'package:flutter/material.dart';
import '../aot_compiler/theme_precompiler.dart';
import '../../state_matrix/atomic_graph.dart';

class TokenResolver {

  static dynamic resolveValue(dynamic raw) {
    if (raw == null) return null;
    
    if (raw is AOTSignalBinding) return raw.value;
    if (raw is AOTColorBinding) return raw.value; 
    
    if (raw is List<AOTChunk>) return raw.map((chunk) => chunk.value?.toString() ?? '').join();
    
    if (raw is String && raw.startsWith(r'$')) {
      return AtomicGraph().getNode(raw.substring(1)).value;
    }
    
    return raw;
  }


  static Color? resolveColor(dynamic rawValue) {
    final dynamic val = resolveValue(rawValue);

    if (val is Color) return val;

    if (val is String && val.startsWith('#')) {
      return _parseHexInternal(val);
    }
    
    return null;
  }


  static Color? _parseHexInternal(String hexValue) {
    try {
      final buffer = StringBuffer();
      String cleanHex = hexValue.replaceFirst('#', '');
      if (cleanHex.length == 6) buffer.write('ff'); 
      buffer.write(cleanHex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }


  static double? resolveSize(dynamic rawValue) {
    final value = resolveValue(rawValue);
    if (value == "100%" || value == "match_parent") return double.infinity;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }


  static FontWeight? resolveWeight(dynamic rawValue) {
    final value = resolveValue(rawValue);
    if (value is int) {
      if (value >= 900) return FontWeight.w900;
      if (value >= 800) return FontWeight.w800;
      if (value >= 700) return FontWeight.bold;
      if (value >= 600) return FontWeight.w600;
      if (value >= 500) return FontWeight.w500;
      if (value >= 400) return FontWeight.normal;
      if (value >= 300) return FontWeight.w300;
      if (value >= 200) return FontWeight.w200;
      return FontWeight.w100;
    }
    if (value is String) {
      if (value == 'bold') return FontWeight.bold;
      if (value == 'normal') return FontWeight.normal;
      if (value == 'w500') return FontWeight.w500;
      if (value == 'light') return FontWeight.w300;
    }
    return null;
  }


  static EdgeInsets resolvePadding(dynamic rawValue) {
    final value = resolveValue(rawValue);
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is List) {
      final list = value.map((e) => (e is num) ? e.toDouble() : 0.0).toList();
      if (list.length == 2) return EdgeInsets.symmetric(horizontal: list[0], vertical: list[1]);
      if (list.length == 4) return EdgeInsets.fromLTRB(list[0], list[1], list[2], list[3]);
    }
    return EdgeInsets.zero;
  }
}