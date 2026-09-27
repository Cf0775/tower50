import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input/key_action.dart';
import '../input/key_bindings.dart';
import '../widgets/feature_phone_menu.dart';
import 'key_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int selectedMenuIndex = 0;
  bool soundEnabled = false;
  final FocusNode _focusNode = FocusNode();
  @override
  void initState() {
    super.initState();
    // 初始化逻辑写这里
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // 释放资源写这里
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKeyEvent(
      FocusNode node,
      KeyEvent event,
      ) {
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

  List<String> get menuItems => [
    '键位设置',
    '声音:${soundEnabled ? '已开启' : '已关闭'}',
  ];


  void _moveUp() {
    setState(() {
      //selectedMenuIndex = (selectedMenuIndex - 1 + menuItems.length) % menuItems.length;//列表循环
      if(selectedMenuIndex>0){
        selectedMenuIndex--;//列表不循环
      }

    });
  }

  void _moveDown() {
    setState(() {
      //selectedMenuIndex = (selectedMenuIndex + 1) % menuItems.length;//列表循环
      if(selectedMenuIndex < menuItems.length - 1){
        selectedMenuIndex++;//列表不循环
      }
    });
  }

  void _confirm([int? index]) {
    final targetIndex = index ?? selectedMenuIndex;
    switch (targetIndex) {
      case 0:
        _openKeySettings();
        break;

      case 1:
        _toggleSound();
        break;
    }
  }

  Future<void> _openKeySettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KeySettingsPage(),
      ),
    );

    if (mounted) {
      _focusNode.requestFocus();
    }
  }

  void _toggleSound() {
    // TODO: 后续实现声音开关
    print('切换声音');
    soundEnabled=!soundEnabled;
    setState(() {

    });
  }

  void _back() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.blue,
      ),

      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: FeaturePhoneMenu(
          title: '设置',
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