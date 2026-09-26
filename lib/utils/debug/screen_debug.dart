import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 打印当前屏幕 / 窗口信息
void debugScreenSize(BuildContext context) {
  if (!kDebugMode) return;

  final size = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);

  debugPrint('========== 屏幕信息 ==========');
  debugPrint(
    '逻辑尺寸: ${size.width.toStringAsFixed(0)} '
        '× ${size.height.toStringAsFixed(0)}',
  );
  debugPrint(
    '物理尺寸: ${(size.width * dpr).toStringAsFixed(0)} '
        '× ${(size.height * dpr).toStringAsFixed(0)}',
  );
  debugPrint('像素密度: $dpr');
  debugPrint(
    '方向: ${size.width < size.height ? "竖屏" : "横屏"}',
  );
  debugPrint('==============================');
}