import sys
import os
import re
from PyQt6.QtWidgets import (QApplication, QMainWindow, QTableWidget, QTableWidgetItem, 
                             QVBoxLayout, QHBoxLayout, QWidget, QPushButton, QStackedWidget, 
                             QTextEdit, QScrollBar, QScrollArea, QLabel, QPlainTextEdit)
from PyQt6.QtGui import (QFont, QKeySequence, QShortcut, QColor, QTextFormat, QPainter, QPalette,
                         QSyntaxHighlighter, QTextCharFormat)
from PyQt6.QtCore import Qt, QTimer, QEvent, QRect

def parse_keybinds_from_readme():
    readme_path = os.path.expanduser("~/hyprland/readme.md")
    keybinds = []
    with open(readme_path, "r") as f:
        content = f.read()
        keybind_section = re.search(r"### Keybinds overview:(.*?)###", content, re.DOTALL)
        if keybind_section:
            lines = keybind_section.group(1).strip().split("\n")
            for line in lines[2:]:
                match = re.match(r"\|\s*`(.+?)`\s*\|\s*(.+?)\s*\|", line)
                if match:
                    keybinds.append((match.group(1), match.group(2)))
    return keybinds

class CustomScrollBar(QScrollBar):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.hide)
        self.valueChanged.connect(self.show)
        self.valueChanged.connect(self.start_timer)
        self.hide()

    def start_timer(self):
        self.timer.start(1500)

class CustomScrollArea(QScrollArea):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setVerticalScrollBar(CustomScrollBar())
        self.verticalScrollBar().hide()

    def enterEvent(self, event):
        self.verticalScrollBar().show()

    def leaveEvent(self, event):
        if not self.verticalScrollBar().isSliderDown():
            self.verticalScrollBar().hide()

class LineNumberArea(QWidget):
    def __init__(self, editor):
        super().__init__(editor)
        self.editor = editor

    def sizeHint(self):
        return QSize(self.editor.line_number_area_width(), 0)

    def paintEvent(self, event):
        self.editor.line_number_area_paint_event(event)

class ConfigEditor(QPlainTextEdit):
    def __init__(self, file_path, parent=None):
        super().__init__(parent)
        self.file_path = file_path
        self.original_content = ""
        self.load_file()
        self.textChanged.connect(self.check_modified)

        self.line_number_area = LineNumberArea(self)
        self.blockCountChanged.connect(self.update_line_number_area_width)
        self.updateRequest.connect(self.update_line_number_area)
        self.cursorPositionChanged.connect(self.highlight_current_line)

        self.update_line_number_area_width(0)
        self.highlight_current_line()

        self.highlighter = SyntaxHighlighter(self.document())

    def load_file(self):
        with open(self.file_path, "r") as f:
            self.original_content = f.read()
            self.setPlainText(self.original_content)

    def check_modified(self):
        return self.toPlainText() != self.original_content

    def save_file(self):
        with open(self.file_path, "w") as f:
            f.write(self.toPlainText())
        self.original_content = self.toPlainText()

    def line_number_area_width(self):
        digits = 1
        max_value = max(1, self.blockCount())
        while max_value >= 10:
            max_value /= 10
            digits += 1
        space = 3 + self.fontMetrics().horizontalAdvance('9') * digits
        return space

    def update_line_number_area_width(self, _):
        self.setViewportMargins(self.line_number_area_width(), 0, 0, 0)

    def update_line_number_area(self, rect, dy):
        if dy:
            self.line_number_area.scroll(0, dy)
        else:
            self.line_number_area.update(0, rect.y(), self.line_number_area.width(), rect.height())
        if rect.contains(self.viewport().rect()):
            self.update_line_number_area_width(0)

    def resizeEvent(self, event):
        super().resizeEvent(event)
        cr = self.contentsRect()
        self.line_number_area.setGeometry(QRect(cr.left(), cr.top(), self.line_number_area_width(), cr.height()))

    def line_number_area_paint_event(self, event):
        painter = QPainter(self.line_number_area)
        painter.fillRect(event.rect(), self.palette().color(QPalette.ColorRole.Window))

        block = self.firstVisibleBlock()
        block_number = block.blockNumber()
        top = self.blockBoundingGeometry(block).translated(self.contentOffset()).top()
        bottom = top + self.blockBoundingRect(block).height()

        current_line = self.textCursor().blockNumber()

        while block.isValid() and top <= event.rect().bottom():
            if block.isVisible() and bottom >= event.rect().top():
                number = str(block_number + 1)
                if block_number == current_line:
                    painter.setPen(QColor("#F38BA8"))
                else:
                    painter.setPen(self.palette().color(QPalette.ColorRole.Text))
                painter.drawText(0, int(top), self.line_number_area.width(), self.fontMetrics().height(),
                                 Qt.AlignmentFlag.AlignRight, number)
            block = block.next()
            top = bottom
            bottom = top + self.blockBoundingRect(block).height()
            block_number += 1

    def highlight_current_line(self):
        extra_selections = []
        if not self.isReadOnly():
            selection = QTextEdit.ExtraSelection()
            line_color = QColor("#0F0F0F")
            selection.format.setBackground(line_color)
            selection.format.setProperty(QTextFormat.Property.FullWidthSelection, True)
            selection.cursor = self.textCursor()
            selection.cursor.clearSelection()
            extra_selections.append(selection)
        self.setExtraSelections(extra_selections)

class SyntaxHighlighter(QSyntaxHighlighter):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.highlighting_rules = []

        keyword_format = QTextCharFormat()
        keyword_format.setForeground(QColor("#F38BA8"))
        keyword_format.setFontWeight(QFont.Weight.Bold)
        keywords = ["monitor", "workspace", "bind", "exec", "windowrule", "general", "decoration", "animations", "gestures", "misc", "input", "device"]
        self.highlighting_rules.extend((r'\b%s\b' % w, keyword_format) for w in keywords)

        value_format = QTextCharFormat()
        value_format.setForeground(QColor("#A6E3A1"))
        self.highlighting_rules.append((r'\b\d+(\.\d+)?\b', value_format))

        comment_format = QTextCharFormat()
        comment_format.setForeground(QColor("#6C7086"))
        self.highlighting_rules.append((r'#.*', comment_format))

        section_format = QTextCharFormat()
        section_format.setForeground(QColor("#89B4FA"))
        section_format.setFontWeight(QFont.Weight.Bold)
        self.highlighting_rules.append((r'^\s*\w+\s*{', section_format))

    def highlightBlock(self, text):
        for pattern, format in self.highlighting_rules:
            for match in re.finditer(pattern, text):
                self.setFormat(match.start(), match.end() - match.start(), format)

class App(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Hyprland Configuration")
        self.setObjectName("HyprlandConfig")
        self.setGeometry(100, 100, 1000, 600)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        layout = QHBoxLayout(central_widget)

        sidebar = QWidget()
        sidebar.setObjectName("Sidebar")
        sidebar_layout = QVBoxLayout(sidebar)
        sidebar_layout.setSpacing(0)
        sidebar_layout.setContentsMargins(0, 0, 0, 0)

        sections = ["Keybinds", "Hyprland.conf", "Hyprpaper.conf"]
        self.section_buttons = []
        for section in sections:
            btn = QPushButton(section)
            btn.setObjectName("SidebarButton")
            sidebar_layout.addWidget(btn)
            self.section_buttons.append(btn)

        sidebar_layout.addStretch()
        layout.addWidget(sidebar, 1)

        self.stack = QStackedWidget()
        layout.addWidget(self.stack, 4)

        keybinds_widget = QWidget()
        keybinds_layout = QVBoxLayout(keybinds_widget)
        self.keybinds_table = QTableWidget()
        self.keybinds_table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.keybinds_table.setFocusPolicy(Qt.FocusPolicy.NoFocus)
        self.keybinds_table.setSelectionMode(QTableWidget.SelectionMode.NoSelection)
        self.keybinds_table.setColumnCount(2)
        self.keybinds_table.setHorizontalHeaderLabels(["Keybind", "Description"])
        self.keybinds_table.horizontalHeader().setStretchLastSection(True)
        self.keybinds_table.verticalHeader().setVisible(False)
        keybinds_scroll_area = CustomScrollArea()
        keybinds_scroll_area.setWidget(self.keybinds_table)
        keybinds_scroll_area.setWidgetResizable(True)
        keybinds_layout.addWidget(keybinds_scroll_area)
        self.stack.addWidget(keybinds_widget)

        hyprland_conf_widget = QWidget()
        hyprland_conf_layout = QVBoxLayout(hyprland_conf_widget)
        self.hyprland_conf_edit = ConfigEditor(os.path.expanduser("~/hyprland/hypr/hyprland.conf"))
        hyprland_conf_scroll_area = CustomScrollArea()
        hyprland_conf_scroll_area.setWidget(self.hyprland_conf_edit)
        hyprland_conf_scroll_area.setWidgetResizable(True)
        self.hyprland_conf_status = QLabel("No unsaved changes")
        hyprland_conf_layout.addWidget(hyprland_conf_scroll_area)
        hyprland_conf_layout.addWidget(self.hyprland_conf_status)
        self.stack.addWidget(hyprland_conf_widget)

        hyprpaper_conf_widget = QWidget()
        hyprpaper_conf_layout = QVBoxLayout(hyprpaper_conf_widget)
        self.hyprpaper_conf_edit = ConfigEditor(os.path.expanduser("~/hyprland/hypr/hyprpaper.conf"))
        hyprpaper_conf_scroll_area = CustomScrollArea()
        hyprpaper_conf_scroll_area.setWidget(self.hyprpaper_conf_edit)
        hyprpaper_conf_scroll_area.setWidgetResizable(True)
        self.hyprpaper_conf_status = QLabel("No unsaved changes")
        hyprpaper_conf_layout.addWidget(hyprpaper_conf_scroll_area)
        hyprpaper_conf_layout.addWidget(self.hyprpaper_conf_status)
        self.stack.addWidget(hyprpaper_conf_widget)

        for i, btn in enumerate(self.section_buttons):
            btn.clicked.connect(lambda _, idx=i: self.stack.setCurrentIndex(idx))

        self.update_keybinds()

        self.save_shortcut = QShortcut(QKeySequence("Ctrl+S"), self)
        self.save_shortcut.activated.connect(self.save_current_config)
        self.hyprland_conf_edit.textChanged.connect(lambda: self.update_status(self.hyprland_conf_status, self.hyprland_conf_edit))
        self.hyprpaper_conf_edit.textChanged.connect(lambda: self.update_status(self.hyprpaper_conf_status, self.hyprpaper_conf_edit))

    def update_keybinds(self):
        keybinds = parse_keybinds_from_readme()
        self.keybinds_table.setRowCount(len(keybinds))
        for row, (keybind, description) in enumerate(keybinds):
            self.keybinds_table.setItem(row, 0, QTableWidgetItem(keybind))
            self.keybinds_table.setItem(row, 1, QTableWidgetItem(description))
        self.keybinds_table.resizeColumnsToContents()

    def save_current_config(self):
        current_widget = self.stack.currentWidget()
        if isinstance(current_widget, QWidget):
            editor = current_widget.findChild(ConfigEditor)
            if editor:
                editor.save_file()
                self.update_status(current_widget.findChild(QLabel), editor)

    def update_status(self, status_label, editor):
        if editor.check_modified():
            status_label.setText("Unsaved changes")
            status_label.setStyleSheet("color: yellow;")
        else:
            status_label.setText("No unsaved changes")
            status_label.setStyleSheet("color: white;")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("HyprlandConfig")
    app.setDesktopFileName("hyprland-config")
    
    css_path = os.path.expanduser("~/hyprland/extra/keybindapp/styles.css")
    with open(css_path, "r") as f:
        app.setStyleSheet(f.read())
    
    window = App()
    window.show()
    sys.exit(app.exec())