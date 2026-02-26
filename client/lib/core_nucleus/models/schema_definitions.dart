class AppSchema {
  final String layoutId;
  final Map<String, dynamic> globalProps;
  final Map<String, Map<String, dynamic>> themes; 
  final Map<String, List<ComponentSpec>> regions;

  AppSchema({
    required this.layoutId,
    required this.globalProps,
    required this.themes,
    required this.regions,
  });

  factory AppSchema.fromMap(Map<String, dynamic> map) {
    return AppSchema(
      layoutId: map['layout_id'] ?? 'layout.unknown',
      globalProps: map['props'] ?? {},
      themes: (map['theme_definitions'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
      ) ?? {},
      regions: (map['regions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List).map((e) => ComponentSpec.fromMap(e)).toList(),
            ),
          ) ?? {},
    );
  }

  factory AppSchema.empty() => AppSchema(layoutId: 'layout.loading', globalProps: {}, themes: {}, regions: {});
}

class ComponentSpec {
  final String type;
  final Map<String, dynamic> props;
  
  ComponentSpec({required this.type, required this.props});

  factory ComponentSpec.fromMap(Map<String, dynamic> map) {
    return ComponentSpec(
      type: map['type'] ?? 'atom.unknown',
      props: map['props'] ?? {},
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'props': props,
    };
  }
}