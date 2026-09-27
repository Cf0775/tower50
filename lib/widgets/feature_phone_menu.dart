import 'package:flutter/material.dart';

class FeaturePhoneMenu extends StatelessWidget {
  const FeaturePhoneMenu({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.title,
    this.showLeftButton = true,
    this.leftButtonText = '菜单',
    this.onLeftButtonPressed,
    this.showRightButton = false,
    this.rightButtonText = '返回',
    this.onRightButtonPressed,
  });

  /// 菜单项
  final List<String> items;

  /// 当前选中的菜单序号
  final int selectedIndex;

  /// 菜单选择事件
  final ValueChanged<int> onItemSelected;

  /// 页面标题
  final String? title;

  /// 是否显示左下角按钮
  final bool showLeftButton;

  /// 左下角按钮文字，例如：菜单、选择、确定
  final String leftButtonText;

  /// 左下角按钮事件
  final VoidCallback? onLeftButtonPressed;

  /// 是否显示右下角按钮
  final bool showRightButton;

  /// 右下角按钮文字，例如：返回
  final String rightButtonText;

  /// 右下角按钮事件
  final VoidCallback? onRightButtonPressed;

  // 颜色定义
  static const Color pageBgColor = Colors.white30;//页面背景颜色
  static const Color titleBgColor = Color(0xFFF6F4EB);
  static const Color titleBorderColor = Color(0xFFD7D2C3);

  static const Color selectedBgColor = Colors.orangeAccent;//选中的一行的背景颜色
  static const Color selectedBorderColor = Color(0xFFE0C386);

  static const Color normalTextColor = Colors.black;
  static const Color selectedTextColor = Colors.black;

  static const Color indexBoxBgColor = Color(0xFFF7F3E8);
  static const Color indexBoxBorderColor = Color(0xFFD0C1A0);
  static const Color indexTextColor = Color(0xFF9E8455);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: pageBgColor,
      child: Column(
        children: [
          // 标题
          if (title != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                color: titleBgColor,
                border: Border(
                  bottom: BorderSide(
                    color: titleBorderColor,
                    width: 1.2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ),

          // 菜单列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final selected = index == selectedIndex;

                return _MenuItem(
                  index: index,
                  text: items[index],
                  selected: selected,
                  onTap: () {
                    onItemSelected(index);
                    print("测试输出");
                  },
                );
              },
            ),
          ),

          // 底部软键区域
          _BottomSoftKeys(
            showLeftButton: showLeftButton,
            leftButtonText: leftButtonText,
            onLeftButtonPressed: onLeftButtonPressed,
            showRightButton: showRightButton,
            rightButtonText: rightButtonText,
            onRightButtonPressed: onRightButtonPressed,
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.index,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = selected
        ? FeaturePhoneMenu.selectedBgColor
        : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 82,
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          border: selected
              ? const Border(
            top: BorderSide(
              color: FeaturePhoneMenu.selectedBorderColor,
              width: 1,
            ),
            bottom: BorderSide(
              color: FeaturePhoneMenu.selectedBorderColor,
              width: 1,
            ),
          )
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 方框序号
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: FeaturePhoneMenu.indexBoxBgColor,
                border: Border.all(
                  color: FeaturePhoneMenu.indexBoxBorderColor,
                  width: 1.6,
                ),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: FeaturePhoneMenu.indexTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ),

            const SizedBox(width: 18),

            // 菜单文字
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? FeaturePhoneMenu.selectedTextColor
                      : FeaturePhoneMenu.normalTextColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSoftKeys extends StatelessWidget {
  const _BottomSoftKeys({
    required this.showLeftButton,
    required this.leftButtonText,
    required this.onLeftButtonPressed,
    required this.showRightButton,
    required this.rightButtonText,
    required this.onRightButtonPressed,
  });

  final bool showLeftButton;
  final String leftButtonText;
  final VoidCallback? onLeftButtonPressed;

  final bool showRightButton;
  final String rightButtonText;
  final VoidCallback? onRightButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: FeaturePhoneMenu.titleBgColor,
        border: Border(
          top: BorderSide(
            color: FeaturePhoneMenu.titleBorderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: showLeftButton
                  ? _SoftKey(
                text: leftButtonText,
                onPressed: onLeftButtonPressed,
              )
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: showRightButton
                  ? _SoftKey(
                text: rightButtonText,
                onPressed: onRightButtonPressed,
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftKey extends StatelessWidget {
  const _SoftKey({
    required this.text,
    this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 8,
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}