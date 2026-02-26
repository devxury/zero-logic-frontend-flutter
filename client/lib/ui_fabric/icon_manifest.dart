import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../token_components/atoms/universal_tokens.dart' show IconDictionary;

/// MANIFIESTO DE ICONOS DEL PROYECTO
/// Aquí  puedes mapera los strings que envía el backend

class AppIconManifest {
  static void injectProjectIcons() {
    IconDictionary.registerAll({
      'moon': PhosphorIconsRegular.moon,
      'sun': PhosphorIconsRegular.sun,
      'users': PhosphorIconsRegular.users,
      'magnifyingGlass': PhosphorIconsRegular.magnifyingGlass,
      'bell': PhosphorIconsRegular.bell,
      'appWindow': PhosphorIconsRegular.appWindow,
      'squaresFour': PhosphorIconsRegular.squaresFour,
      'robot': PhosphorIconsRegular.robot,
      'folder': PhosphorIconsRegular.folder,
      'shieldCheck': PhosphorIconsRegular.shieldCheck,
      'userGear': PhosphorIconsRegular.userGear,
      'gear': PhosphorIconsRegular.gear,
      'caretRight': PhosphorIconsRegular.caretRight,
      'caretDown': PhosphorIconsRegular.caretDown,
      'list': PhosphorIconsRegular.list,
      'house': PhosphorIconsRegular.house,
      'plus': PhosphorIconsRegular.plus,
      'dotsNine': PhosphorIconsRegular.dotsNine,
      'userCircle': PhosphorIconsRegular.userCircle,
      'xCircle': PhosphorIconsRegular.xCircle,
      'toggleLeft': PhosphorIconsRegular.toggleLeft,
      'shieldWarning': PhosphorIconsRegular.shieldWarning,
      'toggleRight': PhosphorIconsRegular.toggleRight,
      'check': PhosphorIconsRegular.check,
      'checkCircle': PhosphorIconsRegular.checkCircle,
      'arrowsClockwise': PhosphorIconsRegular.arrowsClockwise,
      'eye': PhosphorIconsRegular.eye,
      'dotsThreeVertical': PhosphorIconsRegular.dotsThreeVertical,
    });
  }
}