import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/current_game_data.dart';
import '../data/static_value.dart';
import '../utils/debug/screen_debug.dart';
import '../widgets/game_board.dart';

class MainGame extends StatefulWidget {
  const MainGame({super.key});

  @override
  State<MainGame> createState() => _MainGameState();
}

class _MainGameState extends State<MainGame> {
  // 记录上一次窗口尺寸
  Size? _lastSize;

  final CurrentGameData gameData = CurrentGameData();

  // 页面进入、窗口尺寸变化时触发布局调整
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final size = MediaQuery.sizeOf(context);

    if (_lastSize == size) return;

    _lastSize = size;

    debugScreenSize(context);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final boardFlat = gameData.getFloorMap(gameData.currentFloor);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("50层魔塔"),
        actions: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    gameData.currentFloor--;
                  });
                },
                child: const Text('-'),
              ),
              Text("第${gameData.currentFloor}层"),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    gameData.currentFloor++;
                  });
                },
                child: const Text('+'),
              ),
            ],
          ),
        ],
      ),

        body: Column(
          children: [
            // =========================
            // 上方：游戏区域，占 80%
            // =========================
            Expanded(
              flex: 8,
              child: Container(
                width: double.infinity,
                color: const Color(0xFF795548), // 墙棕色
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 取宽高较小的那个，保证 GameBoard 是正方形
                    final side = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;

                    return Center(
                      child: SizedBox(
                        width: side,
                        height: side,
                        child: GameBoard(
                          board: boardFlat,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // =========================
            // 下方：属性 / 道具，占 20%
            // =========================
            Expanded(
              flex: 2,
              child: ScrollConfiguration(
                behavior: const MaterialScrollBehavior().copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,// 此 PageView 支持触控滑动(默认)
                    PointerDeviceKind.mouse, // 此 PageView 支持鼠标拖拽
                  },
                ),
                child: PageView(
                  children: [
                    // 属性栏
                    Container(
                      color: Colors.blueGrey,
                      alignment: Alignment.center,
                      child: const Text(
                        '属性栏',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // 道具栏
                    Container(
                      color: Colors.blueGrey,
                      alignment: Alignment.center,
                      child: const Text(
                        '道具栏',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}
