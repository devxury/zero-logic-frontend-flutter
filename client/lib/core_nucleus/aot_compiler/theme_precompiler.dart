import 'package:flutter/material.dart';
import '../models/schema_definitions.dart';
import '../../state_matrix/atomic_graph.dart';

class AOTCompiler {
  static final _tokenRegex = RegExp(r'\$([a-zA-Z0-9_.]+)');

  static AppSchema compileSchema(AppSchema raw) {
    final compiledRegions = <String, List<ComponentSpec>>{};
    for (var entry in raw.regions.entries) {
      compiledRegions[entry.key] = entry.value.map((c) => compileComponent(c)).toList();
    }
    return AppSchema(
      layoutId: raw.layoutId,
      globalProps: _compileProps(raw.globalProps),
      themes: raw.themes,
      regions: compiledRegions,
    );
  }

  static ComponentSpec compileComponent(ComponentSpec raw) {
    if (raw.props.containsKey('children')) {
      final children = raw.props['children'] as List<dynamic>;
      raw.props['children'] = children.map((child) {
        if (child is Map<String, dynamic>) {
          return compileComponent(ComponentSpec.fromMap(child)).toMap();
        }
        return child;
      }).toList();
    }
    return ComponentSpec(type: raw.type, props: _compileProps(raw.props));
  }

  static Map<String, dynamic> _compileProps(Map<String, dynamic> props) {
    final compiled = <String, dynamic>{};
    
    props.forEach((key, value) {
      if (value is String) {
        if (value.startsWith('#')) {
          compiled[key] = _parseHex(value);
        } 
        else if (value.startsWith('\$')) {
          final tokenPath = value.substring(1);
          if (tokenPath.startsWith('color.') || tokenPath.startsWith('brand.') || tokenPath.startsWith('semantic.')) {
            compiled[key] = AOTColorBinding(tokenPath);
          } else {
            compiled[key] = AOTSignalBinding(tokenPath);
          }
        } 
        else if (_tokenRegex.hasMatch(value)) {
           compiled[key] = _preEvaluateStringChunks(value);
        }
        else {
          compiled[key] = value;
        }
      } else {
        compiled[key] = value;
      }
    });
    return compiled;
  }

  static List<AOTChunk> _preEvaluateStringChunks(String raw) {
    final chunks = <AOTChunk>[];
    int lastMatchEnd = 0;
    for (final match in _tokenRegex.allMatches(raw)) {
      if (match.start > lastMatchEnd) chunks.add(AOTStaticChunk(raw.substring(lastMatchEnd, match.start)));
      chunks.add(AOTSignalChunk(match.group(1)!));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < raw.length) chunks.add(AOTStaticChunk(raw.substring(lastMatchEnd)));
    return chunks;
  }

  static Color _parseHex(String hexValue) {
    try {
      final buffer = StringBuffer();
      String cleanHex = hexValue.replaceFirst('#', '');
      if (cleanHex.length == 6) buffer.write('ff');
      buffer.write(cleanHex);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.transparent;
    }
  }
}

abstract class AOTChunk { dynamic get value; }
class AOTStaticChunk extends AOTChunk { final String text; AOTStaticChunk(this.text); @override String get value => text; }
class AOTSignalChunk extends AOTChunk { final String signalKey; AOTSignalChunk(this.signalKey); @override dynamic get value => AtomicGraph().getNode(signalKey).value; }

class AOTSignalBinding { 
  final String signalKey; 
  AOTSignalBinding(this.signalKey); 
  dynamic get value => AtomicGraph().getNode(signalKey).value; 
}

class AOTColorBinding {
  final String signalKey;
  AOTColorBinding(this.signalKey);
  Color? get value {
    final val = AtomicGraph().getNode(signalKey).value;
    if (val is Color) return val; 
    if (val is String && val.startsWith('#')) {
       return AOTCompiler._parseHex(val); 
    }
    return null;
  }
}