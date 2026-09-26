import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// 跨平台退出应用
Future<void> exitApp(BuildContext context) async {
  // 1. Web 和 iOS：显示提示，不主动退出
  if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS) {
    if (!context.mounted) return;

    final message = kIsWeb
        ? '网页版无法自动退出，请直接关闭浏览器标签页。'
        : 'iOS 不支持应用主动退出，请返回主屏幕，或在多任务界面手动关闭应用。';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('知道了'),
          ),
        ],
      ),
    );

    return;
  }

  // 2. 根据原生平台执行退出
  switch (defaultTargetPlatform) {
  // Android：退出当前 Activity
    case TargetPlatform.android:
      await SystemNavigator.pop();
      return;

    // 桌面平台
    case TargetPlatform.windows:
    // 先隐藏窗口
      await windowManager.hide();

      // 再正常退出应用
      await ServicesBinding.instance.exitApplication(
        AppExitType.required,
      );
      return;

    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      await ServicesBinding.instance.exitApplication(
        AppExitType.required,
      );
      return;

  // Fuchsia：暂不处理
    case TargetPlatform.fuchsia:
      return;

  // iOS 已在前面处理
    case TargetPlatform.iOS:
      return;
  }
}