import 'package:flutter/services.dart';

import 'key_action.dart';

class KeyBindings {
  KeyBindings._();

  static final KeyBindings instance = KeyBindings._();

  final Map<KeyAction, Set<PhysicalKeyboardKey>> _bindings = {
    //上
    KeyAction.up: {
      PhysicalKeyboardKey.arrowUp,
      PhysicalKeyboardKey.keyW,
    },

    //下
    KeyAction.down: {
      PhysicalKeyboardKey.arrowDown,
      PhysicalKeyboardKey.keyS,
    },

    //左
    KeyAction.left: {
      PhysicalKeyboardKey.arrowLeft,
      PhysicalKeyboardKey.keyA,
    },

    //右
    KeyAction.right: {
      PhysicalKeyboardKey.arrowRight,
      PhysicalKeyboardKey.keyD,
    },

    //确认
    KeyAction.confirm: {
      PhysicalKeyboardKey.enter,
      PhysicalKeyboardKey.space,
    },

    //返回
    KeyAction.back: {
      PhysicalKeyboardKey.escape,
      PhysicalKeyboardKey.backspace,
    },

    //菜单
    KeyAction.menu: {
      PhysicalKeyboardKey.keyM,
    },
  };

  /// 获取某个逻辑按键绑定的所有物理按键
  Set<PhysicalKeyboardKey> keysFor(KeyAction action) {
    return Set.unmodifiable(
      _bindings[action] ?? const <PhysicalKeyboardKey>{},
    );
  }

  /// 判断一个物理按键是否属于某个逻辑按键
  bool matches(
      KeyAction action,
      PhysicalKeyboardKey key,
      ) {
    return _bindings[action]?.contains(key) ?? false;
  }

  /// 添加绑定
  void addKey(
      KeyAction action,
      PhysicalKeyboardKey key,
      ) {
    _bindings.putIfAbsent(action, () => {});
    _bindings[action]!.add(key);
  }

  /// 删除某个绑定
  void removeKey(
      KeyAction action,
      PhysicalKeyboardKey key,
      ) {
    _bindings[action]?.remove(key);
  }

  /// 清空某个逻辑按键的全部绑定
  void clearKeys(KeyAction action) {
    _bindings[action]?.clear();
  }

  /// 整组替换
  void setKeys(
      KeyAction action,
      Set<PhysicalKeyboardKey> keys,
      ) {
    _bindings[action] = {...keys};
  }
}