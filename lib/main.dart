import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tower50/pages/main_game_page.dart';
import 'package:tower50/pages/settings_page.dart';
import 'package:tower50/widgets/feature_phone_menu.dart';
import 'package:window_manager/window_manager.dart';

import 'core/platform/exit_app.dart';
import 'input/key_action.dart';
import 'input/key_bindings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        fontFamily: 'SourceHanSansCN',
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int selectedMenuIndex = 0;
  final FocusNode _focusNode = FocusNode();

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

  static const menuItems = ['开始游戏', '载入进度', '设置', '退出'];

  void _moveUp() {
    setState(() {
      //selectedMenuIndex = (selectedMenuIndex - 1 + menuItems.length) % menuItems.length;//列表循环
      if (selectedMenuIndex > 0) {
        selectedMenuIndex--; //列表不循环
      }
    });
  }

  void _moveDown() {
    setState(() {
      //selectedMenuIndex = (selectedMenuIndex + 1) % menuItems.length;//列表循环
      if (selectedMenuIndex < menuItems.length - 1) {
        selectedMenuIndex++; //列表不循环
      }
    });
  }

  void _confirm([int? index]) {
    final targetIndex = index ?? selectedMenuIndex;
    switch (targetIndex) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainGamePage()),
        );
        break;

      case 1:
        _loadGame();
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;

      case 3:
        exitApp(context);
        break;
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    debugPrint(
      '按下物理键: ${event.physicalKey.debugName} '
          'usbHidUsage=${event.physicalKey.usbHidUsage}',
    );

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

    if (bindings.matches(KeyAction.menu, key)) {
      _menu();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _loadGame() {
    // TODO: 以后实现载入进度
  }

  void _menu() {
    // TODO
  }

  void _back() {
    // TODO
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('50层魔塔', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        child: FeaturePhoneMenu(
          title: '主菜单',
          items: menuItems,
          selectedIndex: selectedMenuIndex,
          onItemSelected: (index) {
            setState(() {
              selectedMenuIndex = index;
            });
            _confirm(index);
          },
          showLeftButton: true,
          leftButtonText: "选择",
        ),
      ),
    );
  }
}
