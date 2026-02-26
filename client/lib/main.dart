import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'core_nucleus/config/environment.dart';
import 'core_nucleus/logic/deep_kernel.dart';
import 'core_nucleus/models/schema_definitions.dart';
import 'core_nucleus/services/component_registry.dart';
import 'core_nucleus/utils/token_resolver.dart';
import 'token_components/atoms/universal_tokens.dart';
import 'token_components/atoms/virtual_list.dart'; 
import 'topology_layer/layouts/universal_shell.dart';
import 'topology_layer/z_axis_matrix/overlay_orchestrator.dart';
import 'deferred_blackboxes/video_engine/video_player_blackbox.dart';
import 'state_matrix/atomic_graph.dart'; 
import 'ui_fabric/icon_manifest.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Environment.init();
  } catch (e) {
    debugPrint("⚠️ Env Init Warning: $e");
  }

  _registerCapabilities();

  DeepKernel().bootSequence(); 
  
  runApp(const RootOrchestrator());
}

class RootOrchestrator extends StatelessWidget {
  const RootOrchestrator({super.key});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      if (!DeepKernel().isKernelReady.value) {
        final Color bootBg = TokenResolver.resolveColor(r'$color.background.page') ?? const Color(0xFF121213);
        final Color accentColor = TokenResolver.resolveColor(r'$color.accent.primary') ?? const Color(0xFF00D9F0);
        
        final String bootText = AtomicGraph().getNode('sys.boot_message').value?.toString() ?? 'INICIALIZANDO DEEP CORE...';

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: bootBg,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 24),
                  Text(
                    bootText,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.7), 
                      letterSpacing: 2, 
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Monospace'
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }

      return const DeepCoreRuntime();
    });
  }
}

void _registerCapabilities() {
  AppIconManifest.injectProjectIcons();


  ComponentRegistry.register('layout.loading', (props) => const SizedBox.shrink());
  

  ComponentRegistry.register('layout.auth', (props) => const UniversalShell());
  ComponentRegistry.register('layout.dashboard', (props) => const UniversalShell());
  ComponentRegistry.register('layout.center_focus', (props) => const UniversalShell());
  
  ComponentRegistry.register('layout.error', (props) {
    final bgColor = TokenResolver.resolveColor(r'$semantic.background') ?? Colors.black;
    final errorColor = TokenResolver.resolveColor(r'$semantic.critical') ?? Colors.red;
    final text = props['message']?.toString() ?? 'CRITICAL_RUNTIME_ERROR';

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            text, 
            textAlign: TextAlign.center,
            style: TextStyle(color: errorColor, fontWeight: FontWeight.bold, fontSize: 18)
          ),
        )
      ),
    );
  });


  ComponentRegistry.register('macro.responsive', (props) {
    return LayoutBuilder(builder: (context, constraints) {
      final double mobileBreakpoint = TokenResolver.resolveSize(props['mobile_breakpoint']) ?? 800.0;
      final isMobile = constraints.maxWidth < mobileBreakpoint;
      
      final specMap = isMobile ? props['mobile'] : props['desktop'];
      if (specMap == null) return const SizedBox.shrink();
      
      return ComponentRegistry.build(ComponentSpec.fromMap(specMap));
    });
  });

  ComponentRegistry.register('macro.scaffold', (props) {
    final Color? bgColor = TokenResolver.resolveColor(props['bg_color']);
    
    final Widget? drawerChild = props['drawer'] != null ? ComponentRegistry.build(ComponentSpec.fromMap(props['drawer'])) : null;
    final Widget? drawer = drawerChild != null ? Drawer(backgroundColor: bgColor, child: drawerChild) : null;
    
    final Widget bodyChild = props['body'] != null ? ComponentRegistry.build(ComponentSpec.fromMap(props['body'])) : const SizedBox.shrink();
    final Widget? appBar = props['app_bar'] != null ? ComponentRegistry.build(ComponentSpec.fromMap(props['app_bar'])) : null;

    return Scaffold(
      backgroundColor: bgColor,
      drawer: drawer,
      body: SafeArea(
        child: appBar != null ? Column(children: [appBar, Expanded(child: bodyChild)]) : bodyChild,
      ),
    );
  });

  ComponentRegistry.register('atom.slot', (props) {
    final String regionId = props['name'] ?? '';
    final schema = DeepKernel().activeSchema.value;
    final widgets = schema.regions[regionId]?.map((c) => ComponentRegistry.build(c)).toList() ?? [];
    
    if (widgets.isEmpty) return const SizedBox.shrink();
    if (widgets.length == 1) return widgets.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  });

  ComponentRegistry.register('atom.column', (props) {
      final childrenRaw = props['children'] as List<dynamic>? ?? [];
      final double gap = TokenResolver.resolveSize(props['gap']) ?? 0.0;
      final List<Widget> parsedChildren = [];
      
      for (int i = 0; i < childrenRaw.length; i++) {
        final spec = ComponentSpec.fromMap(childrenRaw[i] as Map<String, dynamic>);
        Widget widget = ComponentRegistry.build(spec);
        
        final dynamic flexRaw = spec.props['flex'];
        final int flex = flexRaw is int ? flexRaw : int.tryParse(flexRaw?.toString() ?? '0') ?? 0;
        
        if (flex > 0) widget = Expanded(flex: flex, child: widget);
        
        parsedChildren.add(widget);
        if (gap > 0 && i < childrenRaw.length - 1) parsedChildren.add(SizedBox(height: gap));
      }
      
      return Column(
        crossAxisAlignment: _resolveCrossAxis(props['align']),
        mainAxisAlignment: _resolveMainAxis(props['justify']),
        children: parsedChildren,
      );
  });


  ComponentRegistry.register('blackbox.video_player', (props) => VideoPlayerBlackbox(props));
  
  ComponentRegistry.register('atom.box', (props) => TokenBox(props));
  ComponentRegistry.register('atom.card', (props) => TokenBox(props));
  
  ComponentRegistry.register('atom.text', (props) => TokenText(props));
  ComponentRegistry.register('atom.button', (props) => TokenButton(props));
  ComponentRegistry.register('atom.input', (props) => TokenInput(props));
  ComponentRegistry.register('atom.icon_button', (props) => TokenIconButton(props));
  ComponentRegistry.register('atom.spacer', (props) => TokenSpacer(props));
  
  ComponentRegistry.register('atom.virtual_list', (props) => VirtualList(props));
  
  ComponentRegistry.register('atom.row', (props) {
      final childrenRaw = props['children'] as List<dynamic>? ?? [];
      final double gap = TokenResolver.resolveSize(props['gap']) ?? 0.0;
      final List<Widget> parsedChildren = [];
      
      for (int i = 0; i < childrenRaw.length; i++) {
        final spec = ComponentSpec.fromMap(childrenRaw[i] as Map<String, dynamic>);
        Widget widget = ComponentRegistry.build(spec);
        
        final dynamic flexRaw = spec.props['flex'];
        final int flex = flexRaw is int ? flexRaw : int.tryParse(flexRaw?.toString() ?? '0') ?? 0;
        
        if (flex > 0) widget = Expanded(flex: flex, child: widget);
        
        parsedChildren.add(widget);
        if (gap > 0 && i < childrenRaw.length - 1) parsedChildren.add(SizedBox(width: gap));
      }
      
      return Row(
        crossAxisAlignment: _resolveCrossAxis(props['align']),
        mainAxisAlignment: _resolveMainAxis(props['justify']),
        children: parsedChildren,
      );
  });
}

CrossAxisAlignment _resolveCrossAxis(dynamic align) {
  if (align == 'center') return CrossAxisAlignment.center;
  if (align == 'end' || align == 'bottom') return CrossAxisAlignment.end;
  if (align == 'stretch') return CrossAxisAlignment.stretch;
  return CrossAxisAlignment.start;
}

MainAxisAlignment _resolveMainAxis(dynamic justify) {
  if (justify == 'center') return MainAxisAlignment.center;
  if (justify == 'end' || justify == 'right') return MainAxisAlignment.end;
  if (justify == 'space_between') return MainAxisAlignment.spaceBetween;
  if (justify == 'space_around') return MainAxisAlignment.spaceAround;
  return MainAxisAlignment.start;
}

class DeepCoreRuntime extends StatelessWidget {
  const DeepCoreRuntime({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final schema = DeepKernel().activeSchema.value;
      
      final String appTitle = AtomicGraph().getNode('app.metadata.title').value?.toString() ?? 'DeepCore OS';
      final String? fontFamily = AtomicGraph().getNode('font.family.primary').value?.toString();
      
      final Color globalBackground = TokenResolver.resolveColor(r'$color.background.page') ?? const Color(0xFF121213);
      
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appTitle,
        theme: ThemeData(
          useMaterial3: false, 
          fontFamily: fontFamily,
          scaffoldBackgroundColor: globalBackground, 
        ),
        home: ZAxisMatrixLayer(
          child: ComponentRegistry.build(
            ComponentSpec(type: schema.layoutId, props: schema.globalProps)
          ),
        ),
      );
    });
  }
}