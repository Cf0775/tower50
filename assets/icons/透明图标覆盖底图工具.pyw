"""Drag a background image, then drop many foreground images to overwrite them.

Dependencies: PyQt6, Pillow
Run: python batch_floor_overlay.py
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageOps, UnidentifiedImageError
from PyQt6.QtCore import QThread, Qt, pyqtSignal
from PyQt6.QtWidgets import (
    QApplication,
    QCheckBox,
    QComboBox,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QProgressBar,
    QPushButton,
    QTextEdit,
    QVBoxLayout,
    QWidget,
)

SUPPORTED_EXTENSIONS = {".png", ".webp", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff"}
FORMAT_BY_EXTENSION = {
    ".png": "PNG",
    ".webp": "WEBP",
    ".jpg": "JPEG",
    ".jpeg": "JPEG",
    ".bmp": "BMP",
    ".tif": "TIFF",
    ".tiff": "TIFF",
}


def background_for_size(base: Image.Image, size: tuple[int, int], mode: str) -> Image.Image:
    """Return an RGBA background covering exactly the foreground canvas."""
    if mode == "拉伸铺满":
        return base.resize(size, Image.Resampling.LANCZOS)

    if mode == "等比裁剪铺满":
        return ImageOps.fit(base, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))

    # Repeat a tile from the upper-left; crop implicitly at the canvas edges.
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    tw, th = base.size
    for y in range(0, size[1], th):
        for x in range(0, size[0], tw):
            canvas.paste(base, (x, y))
    return canvas


def backup_destination(source: Path) -> Path:
    """Never overwrite an earlier backup."""
    candidate = source.with_name(source.name + ".bak")
    number = 1
    while candidate.exists():
        candidate = source.with_name(f"{source.name}.bak.{number}")
        number += 1
    return candidate


def save_atomically(composite: Image.Image, source: Path) -> None:
    """Write beside the original, validate, then atomically replace its path."""
    fmt = FORMAT_BY_EXTENSION[source.suffix.lower()]
    fd, temp_name = tempfile.mkstemp(
        prefix=".floor_overlay_", suffix=source.suffix, dir=str(source.parent)
    )
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        save_options = {}
        result = composite
        if fmt == "JPEG":
            # JPEG does not support alpha. Background makes the result opaque.
            result = composite.convert("RGB")
            save_options = {"quality": 95, "subsampling": 0}
        elif fmt == "WEBP":
            save_options = {"lossless": True, "quality": 100, "method": 4}
        elif fmt == "PNG":
            save_options = {"compress_level": 6}

        result.save(temp_path, format=fmt, **save_options)
        with Image.open(temp_path) as check:
            check.verify()
        os.replace(temp_path, source)
    finally:
        temp_path.unlink(missing_ok=True)


class OverlayWorker(QThread):
    processed = pyqtSignal(int, int, str)  # completed count, total count, log message
    summary = pyqtSignal(int, int)  # success count, failed count

    def __init__(
        self,
        background_path: Path,
        foreground_paths: list[Path],
        mode: str,
        make_backups: bool,
    ) -> None:
        super().__init__()
        self.background_path = background_path
        self.foreground_paths = foreground_paths
        self.mode = mode
        self.make_backups = make_backups

    def run(self) -> None:
        ok = failed = 0
        total = len(self.foreground_paths)
        try:
            with Image.open(self.background_path) as file:
                if getattr(file, "n_frames", 1) != 1:
                    raise ValueError("底图是动图，请换成静态图片")
                base = ImageOps.exif_transpose(file).convert("RGBA")
                base.load()
        except Exception as exc:
            self.processed.emit(0, total, f"❌ 无法读取底图：{exc}")
            self.summary.emit(0, total)
            return

        # Reuse the resized/tiled background for images sharing a canvas size.
        cached_size: tuple[int, int] | None = None
        cached_background: Image.Image | None = None
        for index, path in enumerate(self.foreground_paths, start=1):
            try:
                if path.resolve() == self.background_path.resolve():
                    raise ValueError("不能把底图当作待处理图片")
                with Image.open(path) as file:
                    if getattr(file, "n_frames", 1) != 1:
                        raise ValueError("不支持动图，避免覆盖时丢失动画帧")
                    foreground = ImageOps.exif_transpose(file).convert("RGBA")
                    foreground.load()

                if foreground.size != cached_size:
                    cached_background = background_for_size(base, foreground.size, self.mode)
                    cached_size = foreground.size

                assert cached_background is not None
                result = cached_background.copy()
                result.alpha_composite(foreground)

                # Backup only after successful composite; never replace old backups.
                if self.make_backups:
                    shutil.copy2(path, backup_destination(path))
                save_atomically(result, path)
                ok += 1
                message = f"✅ {path}"
            except Exception as exc:
                failed += 1
                message = f"❌ {path}：{exc}"
            self.processed.emit(index, total, message)
        self.summary.emit(ok, failed)


class OverlayWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.background_path: Path | None = None
        self.worker: OverlayWorker | None = None
        self.setWindowTitle("透明人物 + 地砖背景｜拖拽批量覆盖")
        self.resize(800, 570)
        self.setAcceptDrops(True)

        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        layout.setSpacing(12)
        layout.setContentsMargins(22, 22, 22, 22)

        title = QLabel("先拖 1 张地砖底图，再拖多张透明人物图")
        title.setStyleSheet("font-size: 19px; font-weight: bold;")
        layout.addWidget(title)

        self.background_label = QLabel("底图：尚未设置（从资源管理器拖入第一张图片）")
        self.background_label.setWordWrap(True)
        self.background_label.setMinimumHeight(62)
        self.background_label.setStyleSheet(
            "border: 2px dashed #6484b6; border-radius: 9px; padding: 12px;"
        )
        layout.addWidget(self.background_label)

        row = QHBoxLayout()
        row.addWidget(QLabel("背景适配方式："))
        self.mode_combo = QComboBox()
        self.mode_combo.addItems(["地砖平铺", "拉伸铺满", "等比裁剪铺满"])
        self.mode_combo.setToolTip("平铺保留每块地砖的像素尺寸；拉伸会改变底图比例")
        row.addWidget(self.mode_combo, 1)
        self.backup_checkbox = QCheckBox("覆盖前保留原图 .bak 备份")
        self.backup_checkbox.setChecked(True)
        row.addWidget(self.backup_checkbox)
        layout.addLayout(row)

        button_row = QHBoxLayout()
        self.reset_button = QPushButton("更换底图（下一次拖入即为底图）")
        self.reset_button.clicked.connect(self.reset_background)
        button_row.addWidget(self.reset_button)
        self.status_label = QLabel("等待底图")
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        button_row.addWidget(self.status_label, 1)
        layout.addLayout(button_row)

        self.progress = QProgressBar()
        self.progress.setValue(0)
        layout.addWidget(self.progress)

        self.log = QTextEdit()
        self.log.setReadOnly(True)
        self.log.setPlaceholderText("拖拽记录和每张图片的处理结果显示在这里……")
        layout.addWidget(self.log, 1)

        note = QLabel(
            "支持 PNG / WebP / JPG / BMP / TIFF 静态图片；人物在上层，原路径覆盖。"
            " 建议人物原图使用 PNG/WebP 透明格式。"
        )
        note.setWordWrap(True)
        note.setStyleSheet("color: #666;")
        layout.addWidget(note)

    def dragEnterEvent(self, event) -> None:
        if self.worker is None and event.mimeData().hasUrls() and any(
            url.isLocalFile() for url in event.mimeData().urls()
        ):
            event.acceptProposedAction()
        else:
            event.ignore()

    def dragMoveEvent(self, event) -> None:
        if self.worker is None and event.mimeData().hasUrls():
            event.acceptProposedAction()
        else:
            event.ignore()

    def dropEvent(self, event) -> None:
        if self.worker is not None:
            event.ignore()
            return

        # Explorer file URLs become proper Windows filesystem paths here.
        paths = []
        for url in event.mimeData().urls():
            if url.isLocalFile():
                candidate = Path(url.toLocalFile())
                if candidate.is_file() and candidate.suffix.lower() in SUPPORTED_EXTENSIONS:
                    paths.append(candidate)
        paths = list(dict.fromkeys(paths))
        if not paths:
            self.log.append("⚠️ 未检测到支持的本地图片文件；文件夹不会被递归处理。")
            event.ignore()
            return

        if self.background_path is None:
            if len(paths) != 1:
                self.log.append("⚠️ 第一次请只拖入 1 张底图；本次没有修改任何文件。")
                event.acceptProposedAction()
                return
            path = paths[0]
            try:
                with Image.open(path) as file:
                    if getattr(file, "n_frames", 1) != 1:
                        raise ValueError("不支持动图")
                    file.verify()
            except Exception as exc:
                self.log.append(f"❌ 底图不可用：{path}：{exc}")
                event.acceptProposedAction()
                return
            self.background_path = path
            self.background_label.setText(f"已设置底图：{path}")
            self.status_label.setText("现在拖入一批人物图片")
            self.log.append(f"🧱 底图：{path}")
            event.acceptProposedAction()
            return

        bg = self.background_path.resolve()
        batch = [path for path in paths if path.resolve() != bg]
        if not batch:
            self.log.append("⚠️ 拖入的只有底图，没有可处理的人物图。")
            event.acceptProposedAction()
            return

        self.progress.setRange(0, len(batch))
        self.progress.setValue(0)
        self.status_label.setText(f"正在处理 0 / {len(batch)}")
        self.log.append(
            f"\n▶ 开始处理 {len(batch)} 张；背景方式：{self.mode_combo.currentText()}；"
            f"备份：{'开启' if self.backup_checkbox.isChecked() else '关闭'}"
        )
        self.reset_button.setEnabled(False)
        self.mode_combo.setEnabled(False)
        self.backup_checkbox.setEnabled(False)
        self.worker = OverlayWorker(
            self.background_path,
            batch,
            self.mode_combo.currentText(),
            self.backup_checkbox.isChecked(),
        )
        self.worker.processed.connect(self.on_processed)
        self.worker.summary.connect(self.on_summary)
        self.worker.finished.connect(self.on_worker_finished)
        self.worker.start()
        event.acceptProposedAction()

    def on_processed(self, completed: int, total: int, message: str) -> None:
        self.progress.setValue(completed)
        self.status_label.setText(f"正在处理 {completed} / {total}")
        self.log.append(message)

    def on_summary(self, ok: int, failed: int) -> None:
        self.status_label.setText(f"完成：成功 {ok}，失败 {failed}")
        self.log.append(f"■ 本批结束：成功 {ok}，失败 {failed}\n")

    def on_worker_finished(self) -> None:
        self.worker = None
        self.reset_button.setEnabled(True)
        self.mode_combo.setEnabled(True)
        self.backup_checkbox.setEnabled(True)

    def reset_background(self) -> None:
        if self.worker is not None:
            return
        self.background_path = None
        self.background_label.setText("底图：尚未设置（从资源管理器拖入第一张图片）")
        self.status_label.setText("等待新底图")
        self.progress.setValue(0)
        self.log.append("↺ 已清除底图设置；下一次请只拖入 1 张新底图。")

    def closeEvent(self, event) -> None:
        if self.worker is not None:
            QMessageBox.information(self, "请先完成当前批次", "正在覆盖文件，为避免中断，请在本批完成后关闭。")
            event.ignore()
        else:
            event.accept()


def main() -> None:
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = OverlayWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
