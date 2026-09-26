import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tower50/pages/main_game.dart';
import 'package:window_manager/window_manager.dart';

import 'core/platform/exit_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.windows) {
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
  static const _items = ['开始游戏', '载入进度', '设置','退出'];
  int _selectedIndex = 0;

  void _moveSelection(int delta) {
    setState(() {
      // 加 _items.length 再取余，避免负数
      _selectedIndex = (_selectedIndex + delta + _items.length) % _items.length;
    });
  }

  void _activate() {
    debugPrint('选择了: [$_selectedIndex]${_items[_selectedIndex]}');
    if(_items[_selectedIndex]=="开始游戏"){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainGame()),
      );
    }

    if(_items[_selectedIndex]=="载入进度"){
      //TODO
    }

    if(_items[_selectedIndex]=="设置"){
      //TODO
    }

    if(_items[_selectedIndex]=="退出"){
      exitApp(context);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space) {
      _activate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("50层魔塔"),
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(height: 16), // 项与项之间的间距
                _MenuItem(
                  label: _items[i],
                  selected: i == _selectedIndex,
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    _activate();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        // 内边距，让文字不要贴着边框
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Colors.red : Colors.grey,
            width: 2, // 固定宽度，避免选中时布局抖动
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: selected ? Colors.red : Colors.black87,
          ),
        ),
      ),
    );
  }
}