import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core_nucleus/logic/deep_kernel.dart';
import '../../core_nucleus/models/schema_definitions.dart';
import '../../core_nucleus/services/component_registry.dart';

class UniversalShell extends StatelessWidget {
  const UniversalShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final schema = DeepKernel().activeSchema.value;
      
      final dynamic templateMap = schema.globalProps['template'];
      
      if (templateMap == null || templateMap is! Map<String, dynamic>) {
        return const Scaffold(
          body: Center(child: Text("Missing Layout Template in Database", style: TextStyle(color: Colors.red))),
        );
      }

      final spec = ComponentSpec.fromMap(templateMap);
      return ComponentRegistry.build(spec);
    });
  }
}