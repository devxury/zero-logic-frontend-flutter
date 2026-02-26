import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../core_nucleus/logic/deep_kernel.dart';
import '../../core_nucleus/services/component_registry.dart';

class RegionRenderer extends StatelessWidget {
  final String regionId;

  const RegionRenderer({super.key, required this.regionId});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final schema = DeepKernel().activeSchema.value;
      final components = schema.regions[regionId];

      if (components == null || components.isEmpty) {
        return const SizedBox.shrink(); 
      }


      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: components.map((c) => ComponentRegistry.build(c)).toList(),
      );
    });
  }
}