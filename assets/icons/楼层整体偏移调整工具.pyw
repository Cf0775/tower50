import os
import re
import uuid
from pathlib import Path

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import (
    QApplication,
    QWidget,
    QVBoxLayout,
    QHBoxLayout,
    QPushButton,
    QLabel,
    QTableWidget,
    QTableWidgetItem,
    QHeaderView,
    QMessageBox,
    QAbstractItemView,
)


# ==============================
# 支持文件拖拽的表格
# ==============================

class DropTable(QTableWidget):

    def __init__(self, parent=None):
        super().__init__(parent)

        self.setAcceptDrops(True)
        self.files_dropped = None

    def dragEnterEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
        else:
            event.ignore()

    def dragMoveEvent(self, event):
        if event.mimeData().hasUrls():
            event.acceptProposedAction()
        else:
            event.ignore()

    def dropEvent(self, event):
        paths = [
            Path(url.toLocalFile())
            for url in event.mimeData().urls()
            if url.isLocalFile()
        ]

        if self.files_dropped:
            self.files_dropped(paths)

        event.acceptProposedAction()


# ==============================
# 主窗口
# ==============================

class RenameTool(QWidget):

    def __init__(self):
        super().__init__()

        self.files = []
        self.offset = 0

        self.setWindowTitle("数字文件名批量加减工具")
        self.resize(850, 550)

        self.init_ui()

    # --------------------------
    # 初始化界面
    # --------------------------

    def init_ui(self):

        layout = QVBoxLayout(self)
        layout.setSpacing(12)

        # 标题
        title = QLabel("拖拽数字文件名的文件到下方")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)

        title.setStyleSheet("""
            QLabel {
                font-size: 18px;
                font-weight: bold;
                padding: 15px;
            }
        """)

        layout.addWidget(title)

        # 表格
        self.table = DropTable()

        self.table.setColumnCount(3)

        self.table.setHorizontalHeaderLabels([
            "原文件",
            "修改后文件名",
            "状态"
        ])

        self.table.horizontalHeader().setSectionResizeMode(
            0,
            QHeaderView.ResizeMode.Stretch
        )

        self.table.horizontalHeader().setSectionResizeMode(
            1,
            QHeaderView.ResizeMode.Stretch
        )

        self.table.horizontalHeader().setSectionResizeMode(
            2,
            QHeaderView.ResizeMode.ResizeToContents
        )

        self.table.setEditTriggers(
            QAbstractItemView.EditTrigger.NoEditTriggers
        )

        self.table.setSelectionBehavior(
            QAbstractItemView.SelectionBehavior.SelectRows
        )

        self.table.setAlternatingRowColors(True)

        self.table.files_dropped = self.add_files

        layout.addWidget(self.table)

        # 加减按钮
        button_layout = QHBoxLayout()

        self.minus_btn = QPushButton("-1")
        self.plus_btn = QPushButton("+1")

        self.offset_label = QLabel("当前偏移：0")

        self.offset_label.setAlignment(
            Qt.AlignmentFlag.AlignCenter
        )

        self.offset_label.setStyleSheet("""
            QLabel {
                font-size: 16px;
                font-weight: bold;
            }
        """)

        self.minus_btn.clicked.connect(
            lambda: self.change_offset(-1)
        )

        self.plus_btn.clicked.connect(
            lambda: self.change_offset(1)
        )

        button_layout.addWidget(self.minus_btn)
        button_layout.addWidget(self.offset_label)
        button_layout.addWidget(self.plus_btn)

        layout.addLayout(button_layout)

        # 底部按钮
        bottom_layout = QHBoxLayout()

        self.clear_btn = QPushButton("清空文件")

        self.confirm_btn = QPushButton("确定生效")

        self.clear_btn.clicked.connect(self.clear_files)

        self.confirm_btn.clicked.connect(self.apply_rename)

        self.confirm_btn.setStyleSheet("""
            QPushButton {
                background-color: #238636;
                color: white;
                font-size: 15px;
                font-weight: bold;
                padding: 10px;
            }

            QPushButton:hover {
                background-color: #2ea043;
            }

            QPushButton:disabled {
                background-color: #888888;
            }
        """)

        bottom_layout.addWidget(self.clear_btn)
        bottom_layout.addWidget(self.confirm_btn)

        layout.addLayout(bottom_layout)

        self.status_label = QLabel("等待拖入文件...")

        layout.addWidget(self.status_label)

        self.update_preview()

    # --------------------------
    # 添加文件
    # --------------------------

    def add_files(self, paths):

        added = 0
        ignored = 0

        existing = {
            str(path.absolute())
            for path in self.files
        }

        for path in paths:

            if not path.is_file():
                ignored += 1
                continue

            # 取不含扩展名的部分
            stem = path.stem

            # 必须是纯数字
            if not re.fullmatch(r"[0-9]+", stem):
                ignored += 1
                continue

            key = str(path.absolute())

            # 防止重复添加
            if key in existing:
                continue

            self.files.append(path)

            existing.add(key)

            added += 1

        self.update_preview()

        self.status_label.setText(
            f"已添加 {added} 个文件，"
            f"忽略 {ignored} 个无效文件，"
            f"当前共 {len(self.files)} 个文件"
        )

    # --------------------------
    # 改变偏移量
    # --------------------------

    def change_offset(self, value):

        self.offset += value

        self.update_preview()

    # --------------------------
    # 计算新文件名
    # --------------------------

    def get_new_path(self, path):

        stem = path.stem

        number = int(stem)

        new_number = number + self.offset

        if new_number < 0:
            return None

        # 保留原来的数字宽度和前导零
        new_stem = str(new_number).zfill(len(stem))

        # 保留扩展名
        new_name = new_stem + path.suffix

        return path.with_name(new_name)

    # --------------------------
    # 检查并刷新预览
    # --------------------------

    def update_preview(self):

        self.offset_label.setText(
            f"当前偏移：{self.offset:+d}"
        )

        self.table.setRowCount(len(self.files))

        valid = True

        # 所有参与重命名的原始路径
        source_paths = {
            os.path.normcase(str(p.absolute()))
            for p in self.files
        }

        target_paths = set()

        for row, path in enumerate(self.files):

            new_path = self.get_new_path(path)

            status = "正常"

            if new_path is None:

                new_name = "无效：结果小于 0"

                status = "错误"

                valid = False

            else:

                new_name = new_path.name

                target_key = os.path.normcase(
                    str(new_path.absolute())
                )

                # 检查多个文件是否会变成同一个名字
                if target_key in target_paths:

                    status = "目标文件名重复"

                    valid = False

                # 检查目标文件是否已存在
                # 如果目标本身也在本次重命名列表中，
                # 则允许，因为后续会用临时名称中转。
                elif (
                    os.path.lexists(new_path)
                    and target_key not in source_paths
                ):

                    status = "目标文件已存在"

                    valid = False

                elif not path.is_file():

                    status = "原文件不存在"

                    valid = False

                target_paths.add(target_key)

            # 显示原始完整路径
            original_item = QTableWidgetItem(
                str(path)
            )

            new_item = QTableWidgetItem(
                new_name
            )

            status_item = QTableWidgetItem(
                status
            )

            self.table.setItem(
                row, 0, original_item
            )

            self.table.setItem(
                row, 1, new_item
            )

            self.table.setItem(
                row, 2, status_item
            )

        # 没有文件、偏移为0、有错误时不能执行
        can_apply = (
            len(self.files) > 0
            and self.offset != 0
            and valid
        )

        self.confirm_btn.setEnabled(can_apply)

    # --------------------------
    # 清空
    # --------------------------

    def clear_files(self):

        self.files.clear()

        self.offset = 0

        self.update_preview()

        self.status_label.setText(
            "已清空，等待拖入文件..."
        )

    # --------------------------
    # 真正执行重命名
    # --------------------------

    def apply_rename(self):

        if not self.files or self.offset == 0:
            return

        # 执行之前再次检查
        self.update_preview()

        if not self.confirm_btn.isEnabled():

            QMessageBox.warning(
                self,
                "无法执行",
                "存在无效文件名或文件冲突，请检查列表。"
            )

            return

        # 构建重命名计划
        plans = []

        for old_path in self.files:

            new_path = self.get_new_path(old_path)

            plans.append(
                (old_path, new_path)
            )

        # 最后确认
        reply = QMessageBox.question(
            self,
            "确认修改",
            f"确定将 {len(plans)} 个文件的数字文件名"
            f"统一调整 {self.offset:+d} 吗？",
            QMessageBox.StandardButton.Yes
            | QMessageBox.StandardButton.No,
            QMessageBox.StandardButton.No
        )

        if reply != QMessageBox.StandardButton.Yes:
            return

        # 使用两阶段重命名：
        #
        # 第一阶段：
        # 所有原文件 -> 随机临时文件名
        #
        # 第二阶段：
        # 所有临时文件 -> 最终文件名
        #
        # 这样可以避免：
        # 1.jpg -> 2.jpg
        # 2.jpg -> 3.jpg
        # 过程中发生文件覆盖。

        staged = []
        completed = []

        try:

            # 第一阶段
            for old_path, new_path in plans:

                while True:

                    temp_name = (
                        f".rename_tmp_{uuid.uuid4().hex}"
                    )

                    temp_path = old_path.with_name(
                        temp_name
                    )

                    if not os.path.lexists(temp_path):
                        break

                os.rename(
                    old_path,
                    temp_path
                )

                staged.append(
                    (old_path, temp_path, new_path)
                )

            # 第二阶段
            for old_path, temp_path, new_path in staged:

                # 再次防止覆盖其他文件
                if os.path.lexists(new_path):

                    raise FileExistsError(
                        f"目标文件已存在：{new_path}"
                    )

                os.rename(
                    temp_path,
                    new_path
                )

                completed.append(
                    (old_path, temp_path, new_path)
                )

        except Exception as e:

            # 出错后尝试恢复所有原文件
            rollback_errors = []

            # 已完成的文件先恢复到临时名称
            for old_path, temp_path, new_path in reversed(completed):

                try:

                    os.rename(
                        new_path,
                        temp_path
                    )

                except Exception as rollback_error:

                    rollback_errors.append(
                        str(rollback_error)
                    )

            # 再恢复所有原始文件名
            for old_path, temp_path, new_path in reversed(staged):

                try:

                    if os.path.lexists(temp_path):

                        os.rename(
                            temp_path,
                            old_path
                        )

                except Exception as rollback_error:

                    rollback_errors.append(
                        str(rollback_error)
                    )

            message = (
                f"重命名失败：\n{e}"
            )

            if rollback_errors:

                message += (
                    "\n\n部分文件未能自动恢复，"
                    "请检查原目录：\n"
                    + "\n".join(rollback_errors)
                )

            QMessageBox.critical(
                self,
                "执行失败",
                message
            )

            self.update_preview()

            return

        # 全部成功
        count = len(plans)

        self.files.clear()

        self.offset = 0

        self.update_preview()

        self.status_label.setText(
            f"成功重命名 {count} 个文件"
        )

        QMessageBox.information(
            self,
            "完成",
            f"成功修改 {count} 个文件！"
        )


# ==============================
# 程序入口
# ==============================

if __name__ == "__main__":

    import sys

    app = QApplication(sys.argv)

    window = RenameTool()

    window.show()

    sys.exit(app.exec())