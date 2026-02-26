import 'package:signals/signals.dart';
import 'package:flutter/foundation.dart';
import '../models/schema_definitions.dart';
import '../../state_matrix/atomic_graph.dart';
import '../aot_compiler/theme_precompiler.dart';
import '../local_first_db/storage_core.dart';
import '../services/schema_repository.dart';
import '../../topology_layer/nested_router.dart';

class DeepKernel {
  static final DeepKernel _instance = DeepKernel._internal();
  factory DeepKernel() => _instance;
  DeepKernel._internal();

  final userId = signal<String>("");
  final sessionContext = signal<Map<String, dynamic>>({'role': 'guest'});
  final activeSchema = signal<AppSchema>(AppSchema.empty());
  final isKernelReady = signal<bool>(false);
  final AtomicGraph stateGraph = AtomicGraph();

  String get _fallbackLoginRoute => stateGraph.getNode('sys.route.login').value?.toString() ?? '/login';
  String get _fallbackHomeRoute => stateGraph.getNode('sys.route.home').value?.toString() ?? '/dashboard';


  Future<void> bootSequence() async {
    try {
      await StorageCore().init();
      _restoreSession();

      final manifestsCache = StorageCore().getDocument('sys_cache:manifests');
      
      if (manifestsCache == null) {
        debugPrint("⏳ [Kernel] Primer inicio detectado. Esperando red...");
        await SchemaRepository().bootEngine();
        _loadLocalThemeDictionary();
      } else {
        debugPrint("⚡ [Kernel] Caché encontrada. Iniciando a 0ms...");
        _loadLocalThemeDictionary();
        SchemaRepository().bootEngine().then((_) => _loadLocalThemeDictionary());
      }

      isKernelReady.value = true;

      final initialPath = userId.value.isNotEmpty ? _fallbackHomeRoute : _fallbackLoginRoute;
      NestedRouter().navigateTo(initialPath);

    } catch (e) {
      debugPrint("🛑 [DeepKernel] Boot Error Fatal: $e");
    }
  }


  void _loadLocalThemeDictionary() {
    final themesCache = StorageCore().getDocument('sys_cache:themes')?['data'] as List?;
    if (themesCache == null || themesCache.isEmpty) return;

    String currentThemeId = stateGraph.getNode('current_theme_id').value?.toString() ?? themesCache.first['id'];
    
    final activeTheme = themesCache.firstWhere(
      (t) => t['id'] == currentThemeId, 
      orElse: () => themesCache.first
    );

    if (activeTheme['semantics'] != null) {
      stateGraph.hydrate(Map<String, dynamic>.from(activeTheme['semantics']));
      mutateState('current_theme_id', currentThemeId);
    }
  }

  void injectTopology(AppSchema schema) {
    final compiledSchema = AOTCompiler.compileSchema(schema);
    activeSchema.value = compiledSchema;
  }

  void mutateState(String key, dynamic value) => stateGraph.mutate(key, value);

  void mutateRegion(String regionId, List<ComponentSpec> newComponents) {
    final currentSchema = activeSchema.value;
    final updatedRegions = Map<String, List<ComponentSpec>>.from(currentSchema.regions);
    
    updatedRegions[regionId] = newComponents.map((c) => AOTCompiler.compileComponent(c)).toList();

    activeSchema.value = AppSchema(
      layoutId: currentSchema.layoutId,
      globalProps: currentSchema.globalProps,
      themes: currentSchema.themes,
      regions: updatedRegions,
    );
  }

  Future<void> refreshTopology() async {
    await SchemaRepository().bootEngine();
    _loadLocalThemeDictionary();
  }


  void setSession(String newUser, Map<String, dynamic> contextData) {
    userId.value = newUser;
    sessionContext.value = contextData;
    _persistSession();
    _syncContextToGraph();
    NestedRouter().navigateTo(_fallbackHomeRoute); 
  }

  void updateContextAttribute(String key, dynamic value) {
    final current = Map<String, dynamic>.from(sessionContext.value);
    if (current[key] == value) return;
    current[key] = value;
    sessionContext.value = current;
    _persistSession();
    _syncContextToGraph();
  }

  void logout() {
    userId.value = "";
    sessionContext.value = {'role': 'guest'};
    _persistSession();
    NestedRouter().navigateTo(_fallbackLoginRoute); 
  }

  void _restoreSession() {
    final session = StorageCore().getDocument('sys_session');
    if (session != null) {
      userId.value = session['user_id'] ?? "";
      if (session['context'] is Map) {
        sessionContext.value = Map<String, dynamic>.from(session['context']);
      }
      _syncContextToGraph();
    }
  }

  void _persistSession() {
    StorageCore().saveDocument('sys_session', {
      'id': 'current',
      'user_id': userId.value,
      'context': sessionContext.value
    });
  }

  void _syncContextToGraph() {
    sessionContext.value.forEach((key, value) => stateGraph.mutate('ctx.$key', value));
  }
}