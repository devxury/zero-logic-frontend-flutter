import 'package:flutter/foundation.dart';
import '../utils/token_resolver.dart';
import '../action_queue/intent_dispatcher.dart';

class RuleEvaluator {
  static final RuleEvaluator _instance = RuleEvaluator._internal();
  factory RuleEvaluator() => _instance;
  RuleEvaluator._internal();

  void execute(Map<String, dynamic>? ast) {
    if (ast == null) return;
    try {
      _evaluateNode(ast);
    } catch (e) {
      debugPrint("Error ejecutando Sandbox AST: $e");
    }
  }

  dynamic _evaluateNode(Map<String, dynamic> node) {
    final type = node['type'];

    switch (type) {
      case 'if':
        final bool conditionResult = _evaluateNode(node['condition']);
        if (conditionResult) {
          if (node['then'] != null) _evaluateNode(node['then']);
        } else {
          if (node['else'] != null) _evaluateNode(node['else']);
        }
        return conditionResult;

      case 'compare':
        final left = TokenResolver.resolveValue(node['left']);
        final right = TokenResolver.resolveValue(node['right']);
        final operator = node['operator'];

        return _compare(left, right, operator);

      case 'and':
        final List conditions = node['conditions'] ?? [];
        for (var cond in conditions) {
          if (!_evaluateNode(cond)) return false; 
        }
        return true;

      case 'or':
        final List conditions = node['conditions'] ?? [];
        for (var cond in conditions) {
          if (_evaluateNode(cond)) return true; 
        }
        return false;

      case 'action':
        IntentDispatcher().dispatch(node['action'], node['payload']);
        return true;

      case 'sequence':
        final List steps = node['steps'] ?? [];
        for (var step in steps) {
          _evaluateNode(step);
        }
        return true;

      default:
        debugPrint("⚠️ Regla AST Desconocida: $type");
        return false;
    }
  }

  bool _compare(dynamic left, dynamic right, String operator) {
    double? numLeft = left is num ? left.toDouble() : double.tryParse(left?.toString() ?? '');
    double? numRight = right is num ? right.toDouble() : double.tryParse(right?.toString() ?? '');

    switch (operator) {
      case '==': return left.toString() == right.toString();
      case '!=': return left.toString() != right.toString();
      case '>': return (numLeft != null && numRight != null) ? numLeft > numRight : false;
      case '<': return (numLeft != null && numRight != null) ? numLeft < numRight : false;
      case '>=': return (numLeft != null && numRight != null) ? numLeft >= numRight : false;
      case '<=': return (numLeft != null && numRight != null) ? numLeft <= numRight : false;
      default: return false;
    }
  }
}