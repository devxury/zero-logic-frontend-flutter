import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart'; 
import '../../core_nucleus/services/component_registry.dart';
import '../../core_nucleus/models/schema_definitions.dart';
import '../../core_nucleus/utils/token_resolver.dart';

class VirtualList extends StatelessWidget {
  final Map<String, dynamic> props;
  const VirtualList(this.props, {super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final dynamic rawData = TokenResolver.resolveValue(props['data']);
      final List items = (rawData is List) ? rawData : [];
      
      final Map<String, dynamic> templates = props['templates'] ?? {};

      final bool shrinkWrap = props['shrink_wrap'] == true;
      final ScrollPhysics? physics = shrinkWrap 
          ? const NeverScrollableScrollPhysics() 
          : (props['physics'] == 'bouncing' ? const BouncingScrollPhysics() : const AlwaysScrollableScrollPhysics());
      
      final EdgeInsets padding = props['padding'] != null 
          ? TokenResolver.resolvePadding(props['padding']) 
          : EdgeInsets.zero;

      return ListView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        itemCount: items.length,
        cacheExtent: 500, 
        itemBuilder: (ctx, index) {
          final itemWrapper = items[index];
          if (itemWrapper is! Map) return const SizedBox.shrink();

          final String templateId = itemWrapper['tpl'] ?? itemWrapper['type'] ?? 'default';
          final Map<String, dynamic>? rawTemplate = templates[templateId];

          final Map<String, dynamic> itemData = (itemWrapper['data'] is Map) 
              ? itemWrapper['data'] 
              : Map<String, dynamic>.from(itemWrapper);

          if (rawTemplate == null) return const SizedBox.shrink(); 

          final Map<String, dynamic> hydratedSpec = _hydrateRecursively(rawTemplate, itemData, index);
          return ComponentRegistry.build(ComponentSpec.fromMap(hydratedSpec));
        },
      );
    });
  }

  dynamic _hydrateRecursively(dynamic spec, Map<String, dynamic> data, int index) {
    if (spec is String) {
      if (spec.startsWith(r'$item.')) return data[spec.substring(6)] ?? ""; 
      if (spec == r'$index') return index;
      return spec;
    }
    if (spec is Map) {
      final Map<String, dynamic> copy = {};
      spec.forEach((key, value) => copy[key] = _hydrateRecursively(value, data, index));
      return copy;
    }
    if (spec is List) {
      return spec.map((e) => _hydrateRecursively(e, data, index)).toList();
    }
    return spec;
  }
}