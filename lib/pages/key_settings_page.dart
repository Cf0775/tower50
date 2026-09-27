import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input/key_action.dart';
import '../input/key_bindings.dart';
import '../widgets/feature_phone_menu.dart';
import 'key_edit_page.dart';

class KeySettingsPage extends StatefulWidget {
  const KeySettingsPage({super.key});

  @override
  State<KeySettingsPage> createState() => _KeySettingsPageState();
}

class _KeySettingsPageState extends State<KeySettingsPage> {
  int selectedMenuIndex = 0;
  final FocusNode _focusNode = FocusNode();//焦点

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

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

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

  static const List<KeyAction> actions = [
    KeyAction.up,
    KeyAction.down,
    KeyAction.left,
    KeyAction.right,
    KeyAction.confirm,
    KeyAction.back,
    KeyAction.menu,
  ];

  List<String> get menuItems {
    return actions.map((action) {
      final keys = KeyBindings.instance.keysFor(action);

      final keyText = keys.isEmpty ? '未设置' : keys.map(_keyName).join(' / ');

      return '${action.label}    $keyText';
    }).toList();
  }

  String _keyName(PhysicalKeyboardKey key) {
    if (key == PhysicalKeyboardKey.arrowUp) return '↑';
    if (key == PhysicalKeyboardKey.arrowDown) return '↓';
    if (key == PhysicalKeyboardKey.arrowLeft) return '←';
    if (key == PhysicalKeyboardKey.arrowRight) return '→';

    return key.debugName ?? '未知按键';
  }

  void _moveUp() {
    setState(() {
      if (selectedMenuIndex > 0) {
        selectedMenuIndex--;
      }
    });
  }

  void _moveDown() {
    setState(() {
      if (selectedMenuIndex < menuItems.length - 1) {
        selectedMenuIndex++;
      }
    });
  }

  void _confirm([int? index]) {
    final targetIndex = index ?? selectedMenuIndex;
    _openKeyEdit(actions[targetIndex]);
  }

  Future<void> _openKeyEdit(KeyAction action) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KeyEditPage(action: action)),
    );

    // 从编辑页面回来以后刷新显示
    if (mounted) {
      setState(() {});
      _focusNode.requestFocus();
    }
  }

  void _back() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('键位设置'),
        backgroundColor: Colors.blue,
      ),

      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: FeaturePhoneMenu(
          title: '键位设置',
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
      ),
    );
  }
}
