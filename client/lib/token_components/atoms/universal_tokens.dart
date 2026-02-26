import 'dart:ui' as ui; // Necesario para ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart'; 
import '../../core_nucleus/utils/token_resolver.dart';
import '../../core_nucleus/services/component_registry.dart';
import '../../core_nucleus/models/schema_definitions.dart';
import '../../core_nucleus/action_queue/intent_dispatcher.dart'; 
import '../motion/spring_physics_engine.dart'; 
import '../../state_matrix/atomic_graph.dart'; 

class ReactiveWidget extends StatelessWidget {
  final Widget Function() builder;
  const ReactiveWidget({super.key, required this.builder});
  @override
  Widget build(BuildContext context) {
    return Watch((_) => builder());
  }
}


class TokenBox extends StatelessWidget {
  final Map<String, dynamic> props;
  const TokenBox(this.props, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveWidget(builder: () {
      final double? width = TokenResolver.resolveSize(props['width']);
      final double? height = TokenResolver.resolveSize(props['height']);
      
      EdgeInsets margin = EdgeInsets.zero;
      if (props.containsKey('margin')) {
        margin = TokenResolver.resolvePadding(props['margin']);
      } else {
        final double mt = TokenResolver.resolveSize(props['mt']) ?? 0.0;
        final double mb = TokenResolver.resolveSize(props['mb']) ?? 0.0;
        final double ml = TokenResolver.resolveSize(props['ml']) ?? 0.0;
        final double mr = TokenResolver.resolveSize(props['mr']) ?? 0.0;
        margin = EdgeInsets.only(top: mt, bottom: mb, left: ml, right: mr);
      }
      
      final EdgeInsets? padding = props['padding'] != null 
          ? TokenResolver.resolvePadding(props['padding']) 
          : null;

      final Color? bgColor = TokenResolver.resolveColor(props['bg_color']);
      final Color? borderColor = TokenResolver.resolveColor(props['border_color']);
      final double borderWidth = TokenResolver.resolveSize(props['border_width']) ?? 0.0;
      final double radius = TokenResolver.resolveSize(props['radius']) ?? 0.0;
      final bool isCircle = props['shape'] == 'circle';
      
      Gradient? gradient;
      if (props['gradient'] is List) {
        final colors = (props['gradient'] as List).map((c) => TokenResolver.resolveColor(c) ?? Colors.transparent).toList();
        if (colors.isNotEmpty) {
          gradient = LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
        }
      }

      final double blur = TokenResolver.resolveSize(props['blur']) ?? 0.0;

      List<BoxShadow>? shadows;
      final double elevation = TokenResolver.resolveSize(props['elevation']) ?? 0.0;
      
      if (props['shadow_color'] != null) {
        shadows = [
          BoxShadow(
            color: TokenResolver.resolveColor(props['shadow_color'])!.withOpacity(0.5),
            blurRadius: TokenResolver.resolveSize(props['shadow_blur']) ?? 20,
            offset: const Offset(0, 4),
          )
        ];
      } else if (elevation > 0) {
        final Color shadowCol = TokenResolver.resolveColor(props['shadow_color']) ?? Colors.black.withOpacity(0.12);
        shadows = [
          BoxShadow(
            color: shadowCol,
            blurRadius: elevation * 2,
            offset: Offset(0, elevation / 2),
            spreadRadius: 0,
          )
        ];
      }

      Widget box = Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        clipBehavior: (radius > 0 || isCircle || blur > 0) ? Clip.antiAlias : Clip.none,
        decoration: BoxDecoration(
          color: gradient == null ? bgColor : null,
          gradient: gradient,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(radius),
          boxShadow: shadows,
          border: borderWidth > 0 && borderColor != null
              ? Border.all(color: borderColor, width: borderWidth) 
              : null,
        ),
        child: BackdropFilter(
          filter: blur > 0 
              ? ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur) 
              : ui.ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: props['children'] != null 
            ? _buildChildren(props['children']) 
            : null,
        ),
      );

      final double? opacity = TokenResolver.resolveSize(props['opacity']);
      if (opacity != null && opacity < 1.0) {
        box = Opacity(opacity: opacity, child: box);
      }

      return TokenMotion(props: props, child: box);
    });
  }

  Widget _buildChildren(dynamic rawChildren) {
      final List<dynamic> childrenList = (rawChildren is List) ? rawChildren : [];
      final childrenWidgets = childrenList.map((c) {
        if (c is! Map<String, dynamic>) return const SizedBox.shrink();
        Widget built = ComponentRegistry.build(ComponentSpec.fromMap(c));
        
        final dynamic flexRaw = c['props']?['flex'];
        final int flex = flexRaw is int ? flexRaw : int.tryParse(flexRaw?.toString() ?? '0') ?? 0;
        if (flex > 0) built = Expanded(flex: flex, child: built);
        
        return built;
      }).toList();
      

      return Column(
        crossAxisAlignment: _resolveCrossAxis(props['align']), 
        mainAxisAlignment: _resolveMainAxis(props['justify']),
        mainAxisSize: MainAxisSize.min,
        children: childrenWidgets,
      );
  }

  CrossAxisAlignment _resolveCrossAxis(dynamic align) {
    if (align == 'center') return CrossAxisAlignment.center;
    if (align == 'end' || align == 'right') return CrossAxisAlignment.end;
    if (align == 'stretch') return CrossAxisAlignment.stretch;
    return CrossAxisAlignment.start;
  }
  
  MainAxisAlignment _resolveMainAxis(dynamic justify) {
    if (justify == 'center') return MainAxisAlignment.center;
    if (justify == 'end' || justify == 'bottom') return MainAxisAlignment.end;
    if (justify == 'space_between') return MainAxisAlignment.spaceBetween;
    if (justify == 'space_around') return MainAxisAlignment.spaceAround;
    return MainAxisAlignment.start;
  }
}


class TokenText extends StatelessWidget {
  final Map<String, dynamic> props;
  const TokenText(this.props, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveWidget(builder: () {
      final double mt = TokenResolver.resolveSize(props['mt']) ?? 0.0;
      final double mb = TokenResolver.resolveSize(props['mb']) ?? 0.0;
      final double ml = TokenResolver.resolveSize(props['ml']) ?? 0.0;
      final double mr = TokenResolver.resolveSize(props['mr']) ?? 0.0;
      
      final String text = TokenResolver.resolveValue(props['text'] ?? props['title'] ?? '').toString();
      
      final Color? color = TokenResolver.resolveColor(props['color']);
      final double? size = TokenResolver.resolveSize(props['size']);
      final FontWeight? weight = TokenResolver.resolveWeight(props['weight']);
      final String? fontFamily = TokenResolver.resolveValue(props['font'])?.toString();
      final double? letterSpacing = TokenResolver.resolveSize(props['letter_spacing']);
      final double? lineHeight = TokenResolver.resolveSize(props['line_height']);
      
      final String? decorationStr = TokenResolver.resolveValue(props['decoration'])?.toString();
      TextDecoration? decoration;
      if (decorationStr == 'underline') decoration = TextDecoration.underline;
      if (decorationStr == 'line_through') decoration = TextDecoration.lineThrough;

      final int? maxLines = int.tryParse(props['max_lines']?.toString() ?? '');
      final TextAlign align = _resolveTextAlign(props['align']);

      Widget txt = Padding(
        padding: EdgeInsets.only(top: mt, bottom: mb, left: ml, right: mr),
        child: Text(
          text,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          textAlign: align,
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            fontFamily: fontFamily,
            letterSpacing: letterSpacing,
            height: lineHeight,
            decoration: decoration,
          ),
        ),
      );

      return TokenMotion(props: props, child: txt);
    });
  }

  TextAlign _resolveTextAlign(dynamic align) {
    if (align == 'center') return TextAlign.center;
    if (align == 'right' || align == 'end') return TextAlign.right;
    if (align == 'justify') return TextAlign.justify;
    return TextAlign.left;
  }
}


class TokenButton extends StatelessWidget {
  final Map<String, dynamic> props;
  const TokenButton(this.props, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveWidget(builder: () {
      final double mt = TokenResolver.resolveSize(props['mt']) ?? 0.0;
      final double mb = TokenResolver.resolveSize(props['mb']) ?? 0.0;
      
      final bool disabled = props['disabled'] == true;
      final double opacity = disabled 
          ? (TokenResolver.resolveSize(props['disabled_opacity']) ?? 0.5) 
          : 1.0;

      final double? width = TokenResolver.resolveSize(props['width']);
      final double radius = TokenResolver.resolveSize(props['radius']) ?? 8.0; 

      final Color? bgColor = TokenResolver.resolveColor(props['bg_color']);
      final Color? borderColor = TokenResolver.resolveColor(props['border_color']);
      final double borderWidth = TokenResolver.resolveSize(props['border_width']) ?? 1.0;
      final EdgeInsets padding = props['padding'] != null 
          ? TokenResolver.resolvePadding(props['padding']) 
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

      final Color? textColor = TokenResolver.resolveColor(props['text_color']);
      final double? textSize = TokenResolver.resolveSize(props['size']);
      final FontWeight? weight = TokenResolver.resolveWeight(props['weight']);
      final double? letterSpacing = TokenResolver.resolveSize(props['letter_spacing']);
      
      final Alignment alignment = _resolveAlignment(props['align']);

      Widget btn = Padding(
        padding: EdgeInsets.only(top: mt, bottom: mb),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => IntentDispatcher().dispatch(props['action'], props['payload']),
            borderRadius: BorderRadius.circular(radius),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: width,
                padding: padding,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(radius),
                  border: borderColor != null 
                      ? Border.all(color: borderColor, width: borderWidth) 
                      : null,
                ),
                alignment: alignment, 
                child: Text(
                  TokenResolver.resolveValue(props['label'] ?? '').toString(),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: weight,
                    fontSize: textSize,
                    letterSpacing: letterSpacing,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      return TokenMotion(props: props, child: btn);
    });
  }

  Alignment _resolveAlignment(dynamic align) {
    if (align == 'left' || align == 'start') return Alignment.centerLeft;
    if (align == 'right' || align == 'end') return Alignment.centerRight;
    return Alignment.center;
  }
}


class TokenInput extends StatefulWidget {
  final Map<String, dynamic> props;
  const TokenInput(this.props, {super.key});

  @override
  State<TokenInput> createState() => _TokenInputState();
}

class _TokenInputState extends State<TokenInput> {
  late TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    
    final boundKey = TokenResolver.resolveValue(widget.props['bind_key'])?.toString();
    if (boundKey != null) {
      _controller.text = AtomicGraph().getNode(boundKey).value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final boundKey = TokenResolver.resolveValue(widget.props['bind_key'])?.toString();

    if (boundKey != null) {
      final signalValue = AtomicGraph().getNode(boundKey).watch(context)?.toString() ?? '';
      
      if (_controller.text != signalValue) {
        _controller.value = _controller.value.copyWith(
          text: signalValue,
          selection: TextSelection.collapsed(offset: signalValue.length),
        );
      }
    }

    final double mb = TokenResolver.resolveSize(widget.props['mb']) ?? 0.0;
    final double? width = TokenResolver.resolveSize(widget.props['width']);
    final double? height = TokenResolver.resolveSize(widget.props['height']);
    
    final Color? bgColor = TokenResolver.resolveColor(widget.props['bg_color']);
    final double radius = TokenResolver.resolveSize(widget.props['radius']) ?? 8.0;
    
    final Color? textColor = TokenResolver.resolveColor(widget.props['text_color']);
    final double? textSize = TokenResolver.resolveSize(widget.props['size']);
    
    final Color? borderColor = TokenResolver.resolveColor(widget.props['border_color']);
    final double borderWidth = TokenResolver.resolveSize(widget.props['border_width']) ?? 1.0;
    
    InputBorder border = borderColor != null 
      ? OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: borderColor, width: borderWidth))
      : InputBorder.none;

    final int lines = int.tryParse(widget.props['lines']?.toString() ?? '1') ?? 1;

    return TokenMotion(
      props: widget.props,
      child: Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(bottom: mb),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(radius)),
        child: TextField(
          controller: _controller,
          maxLines: lines,
          obscureText: widget.props['is_password'] == true,
          style: TextStyle(color: textColor, fontSize: textSize),
          decoration: InputDecoration(
            labelText: TokenResolver.resolveValue(widget.props['label'])?.toString(),
            labelStyle: TextStyle(color: TokenResolver.resolveColor(widget.props['hint_color']), fontSize: textSize),
            border: border, enabledBorder: border, focusedBorder: border, 
            contentPadding: widget.props['padding'] != null 
                ? TokenResolver.resolvePadding(widget.props['padding']) 
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (val) {
             if (boundKey != null) AtomicGraph().mutate(boundKey, val);
          },
        ),
      ),
    );
  }
}


class TokenIconButton extends StatelessWidget {
  final Map<String, dynamic> props;
  const TokenIconButton(this.props, {super.key});

  @override
  Widget build(BuildContext context) {
    return ReactiveWidget(builder: () {
      final double radius = TokenResolver.resolveSize(props['radius']) ?? 999.0;
      final EdgeInsets padding = props['padding'] != null 
          ? TokenResolver.resolvePadding(props['padding']) 
          : const EdgeInsets.all(8.0);
          
      final Color? bgColor = TokenResolver.resolveColor(props['bg_color']);
      final Color? borderColor = TokenResolver.resolveColor(props['border_color']);
      final double borderWidth = TokenResolver.resolveSize(props['border_width']) ?? 1.0;
      
      final double mb = TokenResolver.resolveSize(props['mb']) ?? 0.0;

      Widget iconBtn = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => IntentDispatcher().dispatch(props['action'], props['payload']),
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(radius),
              border: borderColor != null 
                  ? Border.all(color: borderColor, width: borderWidth) 
                  : null,
            ),
            child: _buildAgnosticIcon(),
          ),
        ),
      );

      return Padding(
        padding: EdgeInsets.only(bottom: mb),
        child: TokenMotion(props: props, child: iconBtn)
      );
    });
  }

  Widget _buildAgnosticIcon() {
    final Color? iconColor = TokenResolver.resolveColor(props['color']);
    final double? iconSize = TokenResolver.resolveSize(props['size']);
    
    final dynamic rawIcon = TokenResolver.resolveValue(props['icon']);
    final String iconFamily = TokenResolver.resolveValue(props['icon_family'])?.toString() ?? 'MaterialIcons';
    final String? fontPackage = TokenResolver.resolveValue(props['font_package'])?.toString();

    if (rawIcon == null) return const SizedBox.shrink();

    int? codePoint;

    if (rawIcon is int) {
      codePoint = rawIcon;
    } 
    else if (rawIcon is String) {
      codePoint = int.tryParse(rawIcon) ?? int.tryParse(rawIcon.replaceFirst('0x', ''), radix: 16);
      
      if (codePoint == null) {
        final injectedIcon = IconDictionary.resolve(rawIcon);
        if (injectedIcon != null) {
          return Icon(injectedIcon, color: iconColor, size: iconSize);
        }
      }
    }

    if (codePoint != null) {
      return Icon(
        IconData(codePoint, fontFamily: iconFamily, fontPackage: fontPackage),
        color: iconColor,
        size: iconSize,
      );
    }
    
    return const SizedBox.shrink(); 
  }
}


class TokenSpacer extends StatelessWidget {
  final Map<String, dynamic> props;
  const TokenSpacer(this.props, {super.key});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: TokenResolver.resolveSize(props['height']), 
      width: TokenResolver.resolveSize(props['width'])
    );
  }
}


class IconDictionary {
  static final Map<String, IconData> _registry = {};

  static void register(String alias, IconData data) {
    _registry[alias] = data;
  }
  
  static void registerAll(Map<String, IconData> icons) {
    _registry.addAll(icons);
  }

  static IconData? resolve(String alias) => _registry[alias];
}