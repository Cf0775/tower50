import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input/key_action.dart';
import '../input/key_bindings.dart';
import '../widgets/feature_phone_menu.dart';

class KeyEditPage extends StatefulWidget {
  const KeyEditPage({super.key, required this.action});

  final KeyAction action;

  @override
  State<KeyEditPage> createState() => _KeyEditPageState();
}

class _KeyEditPageState extends State<KeyEditPage> {
  int selectedMenuIndex = 0;
  final FocusNode _focusNode = FocusNode();
  bool waitingForKey = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<PhysicalKeyboardKey> get boundKeys {
    return KeyBindings.instance.keysFor(widget.action).toList();
  }

  List<String> get menuItems {
    final items = <String>[
      ...boundKeys.map((key) => '删除：${_keyName(key)}'),
      '添加按键',
      '清空全部',
    ];

    return items;
  }

  String _keyName(PhysicalKeyboardKey key) {
    return key.debugName ?? '未知按键';
  }

  void _moveUp() {
    if (waitingForKey) {
      return;
    }

    setState(() {
      if (selectedMenuIndex > 0) {
        selectedMenuIndex--;
      }
    });
  }

  void _moveDown() {
    if (waitingForKey) {
      return;
    }

    setState(() {
      if (selectedMenuIndex < menuItems.length - 1) {
        selectedMenuIndex++;
      }
    });
  }

  void _confirm([int? index]) {
    if (waitingForKey) {
      return;
    }

    final targetIndex = index ?? selectedMenuIndex;

    final keys = boundKeys;

    // 前面的项目都是已有键位，选择以后删除
    if (targetIndex < keys.length) {
      _removeKey(keys[targetIndex]);
      return;
    }

    final addIndex = keys.length;
    final clearIndex = keys.length + 1;

    if (targetIndex == addIndex) {
      _startWaitingForKey();
      return;
    }

    if (targetIndex == clearIndex) {
      _clearKeys();
    }
  }

  void _removeKey(PhysicalKeyboardKey key) {
    setState(() {
      KeyBindings.instance.removeKey(widget.action, key);

      if (selectedMenuIndex >= menuItems.length) {
        selectedMenuIndex = menuItems.length - 1;
      }

      if (selectedMenuIndex < 0) {
        selectedMenuIndex = 0;
      }
    });
  }

  void _clearKeys() {
    setState(() {
      KeyBindings.instance.clearKeys(widget.action);
      selectedMenuIndex = 0;
    });
  }

  void _startWaitingForKey() {
    setState(() {
      waitingForKey = true;
    });
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // 等待录入时，任何物理按键都作为新绑定
    if (waitingForKey) {
      setState(() {
        KeyBindings.instance.addKey(widget.action, event.physicalKey);

        waitingForKey = false;
      });

      return KeyEventResult.handled;
    }

    // 正常菜单控制
    final key = event.physicalKey;
    final bindings = KeyBindings.instance;

    if (bindings.matches(KeyAction.up, key)) {
      _moveUp();
      return KeyEventResult.handled;
    }

    if (bindings.matches(KeyAction.down, key)) {
      _moveDown();
      return KeyEventResult.handled;
    }

    if (bindings.matches(KeyAction.confirm, key)) {
      _confirm();
      return KeyEventResult.handled;
    }

    if (bindings.matches(KeyAction.back, key)) {
      _back();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _back() {
    if (waitingForKey) {
      setState(() {
        waitingForKey = false;
      });

      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.action.label} - 键位编辑'),
        backgroundColor: Colors.blue,
      ),

      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: Stack(
          children: [
            FeaturePhoneMenu(
              title: '${widget.action.label}键',
              items: menuItems,
              selectedIndex: selectedMenuIndex,

              onItemSelected: (index) {
                setState(() {
                  selectedMenuIndex = index;
                });

                _confirm(index);
              },

              showLeftButton: false,

              showRightButton: true,
              rightButtonText: '返回',
              onRightButtonPressed: _back,
            ),

            if (waitingForKey)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Text(
                      '请按下要绑定到「${widget.action.label}」的按键',
                      style: const TextStyle(fontSize: 22, color: Colors.black),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
