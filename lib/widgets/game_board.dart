import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/current_game_data.dart';

class GameBoard extends StatefulWidget {
  final List<List<int>> board;

  const GameBoard({
    super.key,
    required this.board,
  });

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  ui.Image? _mapImage;

  /// 缓存所有素材图片
  final Map<int, ui.Image> _imageCache = {};

  static const int rowCount = 11;
  static const int colCount = 11;

  /// 每个格子的原始像素大小，这里是 32
  static const double tileSize = 32;

  @override
  void initState() {
    super.initState();
    _buildMap();
  }

  @override
  void didUpdateWidget(covariant GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // board 改变后重新生成地图
    _buildMap();
  }

  /// 加载单个图片，并缓存
  Future<ui.Image> _loadImage(int value) async {
    final cached = _imageCache[value];
    if (cached != null) {
      return cached;
    }

    final data = await rootBundle.load(
      'assets/icons/$value.png',
    );

    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );

    final frame = await codec.getNextFrame();

    _imageCache[value] = frame.image;

    return frame.image;
  }

  /// 将整个 11 × 11 地图拼成一张 ui.Image
  Future<void> _buildMap() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    // 先获取当前地图需要的所有图片
    final values = <int>{};

    for (final row in widget.board) {
      values.addAll(row);
    }

    // 把我自己的图片也加入需要加载的素材
    values.add(45);
    values.add(46);
    values.add(47);
    values.add(48);

    // 并行加载素材
    await Future.wait(
      values.map(_loadImage),
    );

    //获取玩家位置
    final gameData = CurrentGameData();
    int myRow = gameData.currentRow;
    int myColumn = gameData.currentColumn;
    //int myFloor = gameData.currentFloor;

    // 绘制整个地图
    for (int row = 0; row < rowCount; row++) {
      for (int col = 0; col < colCount; col++) {
        int value = widget.board[row][col];
        if (row == myRow && col == myColumn) {
          value = 46; // 我的角色图片编号
        }

        final image = _imageCache[value];

        if (image == null) {
          continue;
        }

        final src = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );

        final dst = Rect.fromLTWH(
          col * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );

        canvas.drawImageRect(
          image,
          src,
          dst,
          paint,
        );
      }
    }


    final picture = recorder.endRecording();

    final image = await picture.toImage(
      (colCount * tileSize).toInt(),
      (rowCount * tileSize).toInt(),
    );

    if (!mounted) {
      image.dispose();
      return;
    }

    // 释放上一张地图
    _mapImage?.dispose();

    setState(() {
      _mapImage = image;
    });
  }

  @override
  void dispose() {
    _mapImage?.dispose();

    for (final image in _imageCache.values) {
      image.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _mapImage;

    if (image == null) {
      return const SizedBox();
    }

    return AspectRatio(
      aspectRatio: 1,
      child: RawImage(
        image: image,
        fit: BoxFit.fill,

        // 像素风游戏建议关闭插值
        filterQuality: FilterQuality.none,
      ),
    );
  }
}