import 'package:flutter/foundation.dart';
import '../core_nucleus/logic/deep_kernel.dart';
import '../core_nucleus/models/schema_definitions.dart';
import '../core_nucleus/services/schema_repository.dart';
import '../core_nucleus/local_first_db/storage_core.dart';
import '../state_matrix/atomic_graph.dart';

class NestedRouter {
  static final NestedRouter _instance = NestedRouter._internal();
  factory NestedRouter() => _instance;
  NestedRouter._internal();

  Future<void> navigateTo(String path) async {
    try {
      final manifestsCache = StorageCore().getDocument('sys_cache:manifests')?['data'] as List?;
      final layoutsCache = StorageCore().getDocument('sys_cache:layouts')?['data'] as List?;
      final fragmentsCache = StorageCore().getDocument('sys_cache:fragments')?['data'] as List?;

      if (manifestsCache == null) return;

      final role = DeepKernel().sessionContext.value['role'] ?? 'guest';
      
      final manifest = manifestsCache.firstWhere(
        (m) => m['path'] == path && m['role'] == role,
        orElse: () => null,
      );

      if (manifest == null) {
        DeepKernel().injectTopology(AppSchema(
           layoutId: 'layout.error',
           globalProps: {'message': '404 UI Manifest Not Found\nPath: $path | Role: $role'},
           themes: {}, 
           regions: {},
        ));
        debugPrint("[Edge Router] 404 No se encontró Manifest para Path: $path, Role: $role");
        return;
      }

      final layoutId = manifest['layout_id'];
      final layoutDef = layoutsCache?.firstWhere((l) => l['id'] == layoutId, orElse: () => null);
      
      if (layoutDef != null) {
        Map<String, List<ComponentSpec>> compiledRegions = {};
        
        Map<String, dynamic> slots = manifest['slots'] ?? {};
        slots.forEach((regionName, fragmentIds) {
           List<ComponentSpec> specs = [];
           for (String fId in fragmentIds) {
              final frag = fragmentsCache?.firstWhere((f) => f['id'] == fId, orElse: () => null);
              if (frag != null) {
                 specs.add(ComponentSpec(type: frag['type'], props: frag['props']));
              }
           }
           compiledRegions[regionName] = specs;
        });

        DeepKernel().injectTopology(AppSchema(
           layoutId: layoutId,
           globalProps: layoutDef['props'] ?? {}, 
           themes: {}, 
           regions: compiledRegions,
        ));
      }

      final hydrationData = await SchemaRepository().hydrateRoute(path);
      
      if (hydrationData.containsKey('view_model')) {
        AtomicGraph().hydrate(hydrationData['view_model']);
      }
      if (hydrationData.containsKey('trace_id')) {
         DeepKernel().mutateState('sys.current_trace_id', hydrationData['trace_id']);
      }

    } catch (e) {
      debugPrint("[Edge Router] Error ensamblando vista local: $e");
    }
  }

  Future<void> navigateSlot({required String regionId, required String targetId}) async {
    try {
      DeepKernel().mutateRegion(regionId, [
        ComponentSpec(type: 'atom.text', props: {'text': '...', 'color': '\$semantic.text_muted'})
      ]);

      final fragmentsCache = StorageCore().getDocument('sys_cache:fragments')?['data'] as List?;
      final frag = fragmentsCache?.firstWhere((f) => f['id'] == targetId, orElse: () => null);

      if (frag != null) {
         DeepKernel().mutateRegion(regionId, [
            ComponentSpec(type: frag['type'], props: frag['props'])
         ]);
      } else {
         DeepKernel().mutateRegion(regionId, [
            ComponentSpec(type: 'atom.text', props: {'text': '404 Fragment Missing', 'color': '\$semantic.critical'})
         ]);
      }
    } catch (e) {
      debugPrint("[Dexxury Router] Fallo en navegación de Slot: $e");
    }
  }
}