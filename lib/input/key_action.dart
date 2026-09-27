enum KeyAction {
  up,
  down,
  left,
  right,
  confirm,
  back,
  menu,
}

extension KeyActionExtension on KeyAction {
  String get label {
    switch (this) {
      case KeyAction.up:
        return '上';

      case KeyAction.down:
        return '下';

      case KeyAction.left:
        return '左';

      case KeyAction.right:
        return '右';

      case KeyAction.confirm:
        return '确认';

      case KeyAction.back:
        return '返回';

      case KeyAction.menu:
        return '菜单';
    }
  }
}