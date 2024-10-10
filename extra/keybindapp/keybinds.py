import sys
import os
import re
from PyQt6.QtWidgets import (QApplication, QMainWindow, QTableWidget, QTableWidgetItem, 
                             QVBoxLayout, QHBoxLayout, QWidget, QPushButton, QStackedWidget, 
                             QTextEdit, QScrollBar, QScrollArea, QLabel, QPlainTextEdit, 
                             QCheckBox, QSpinBox, QComboBox, QColorDialog, QTabWidget,
                             QScrollArea, QFormLayout, QGroupBox)
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
        keyword_format.setForeground(QColor("white"))
        keyword_format.setFontWeight(QFont.Weight.Bold)
        keywords = ["monitor", "workspace", "bind", "exec", "windowrule", "general", "decoration", "animations", "gestures", "misc", "input", "device"]
        self.highlighting_rules.extend((r'\b%s\b' % w, keyword_format) for w in keywords)

        value_format = QTextCharFormat()
        value_format.setForeground(QColor("white"))
        self.highlighting_rules.append((r'\b\d+(\.\d+)?\b', value_format))

        comment_format = QTextCharFormat()
        comment_format.setForeground(QColor("#6C7086"))
        self.highlighting_rules.append((r'#.*', comment_format))

        section_format = QTextCharFormat()
        section_format.setForeground(QColor("white"))
        section_format.setFontWeight(QFont.Weight.Bold)
        self.highlighting_rules.append((r'^\s*\w+\s*{', section_format))

    def highlightBlock(self, text):
        for pattern, format in self.highlighting_rules:
            for match in re.finditer(pattern, text):
                self.setFormat(match.start(), match.end() - match.start(), format)

class ColorButton(QPushButton):
    def __init__(self, color=None, parent=None):
        super().__init__(parent)
        self.setFixedSize(32, 32)
        self.color = color or QColor("#FFFFFF")
        self.setColor(self.color)
        self.clicked.connect(self.choose_color)

    def setColor(self, color):
        if isinstance(color, str):
            color = QColor(color)
        self.color = color
        self.setStyleSheet(f"background-color: {self.color.name()}; border: 1px solid #45475A; border-radius: 3px;")

    def choose_color(self):
        color = QColorDialog.getColor(self.color, self.parent(), "Choose Color")
        if color.isValid():
            self.setColor(color)

    def getColor(self):
        return self.color

class HyprlandConfigWidget(QWidget):
    def __init__(self, config_path):
        super().__init__()
        self.config_path = config_path
        self.config_data = {}
        self.load_config()
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 20, 20, 20)
        layout.setSpacing(20)

        self.tab_widget = QTabWidget()
        layout.addWidget(self.tab_widget)

        self.create_general_tab()
        self.create_decoration_tab()
        self.create_animations_tab()
        self.create_input_tab()

        save_button = QPushButton("Save Configuration")
        save_button.clicked.connect(self.save_config)
        save_button.setObjectName("SaveButton")
        layout.addWidget(save_button)

    def create_general_tab(self):
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        general_widget = QWidget()
        general_layout = QVBoxLayout(general_widget)
        general_layout.setContentsMargins(10, 10, 10, 10)
        general_layout.setSpacing(15)

        gaps_group = QGroupBox("Gaps")
        gaps_layout = QFormLayout()
        gaps_layout.setContentsMargins(10, 10, 10, 10)
        gaps_layout.setSpacing(10)
        self.gaps_in = QSpinBox()
        self.gaps_out = QSpinBox()
        gaps_layout.addRow("Inner:", self.gaps_in)
        gaps_layout.addRow("Outer:", self.gaps_out)
        gaps_group.setLayout(gaps_layout)
        general_layout.addWidget(gaps_group)

        border_group = QGroupBox("Border")
        border_layout = QFormLayout()
        border_layout.setContentsMargins(10, 10, 10, 10)
        border_layout.setSpacing(10)
        self.border_size = QSpinBox()
        self.border_size.setRange(0, 10)
        self.active_border_color = ColorButton()
        self.inactive_border_color = ColorButton()
        border_layout.addRow("Size:", self.border_size)
        border_layout.addRow("Active color:", self.active_border_color)
        border_layout.addRow("Inactive color:", self.inactive_border_color)
        border_group.setLayout(border_layout)
        general_layout.addWidget(border_group)

        layout_group = QGroupBox("Layout")
        layout_layout = QFormLayout()
        layout_layout.setContentsMargins(10, 10, 10, 10)
        layout_layout.setSpacing(10)
        self.layout = QComboBox()
        self.layout.addItems(["dwindle", "master"])
        layout_layout.addRow("Type:", self.layout)
        layout_group.setLayout(layout_layout)
        general_layout.addWidget(layout_group)

        general_layout.addStretch(1)
        scroll_area.setWidget(general_widget)
        self.tab_widget.addTab(scroll_area, "General")

        self.set_general_values()

    def create_decoration_tab(self):
        pass

    def create_animations_tab(self):
        pass

    def create_input_tab(self):
        pass

    def load_config(self):
        with open(self.config_path, 'r') as f:
            lines = f.readlines()
        
        current_section = None
        for line in lines:
            line = line.strip()
            if line.endswith('{'):
                current_section = line.split()[0]
                self.config_data[current_section] = {}
            elif line.startswith('}'):
                current_section = None
            elif '=' in line and current_section:
                key, value = map(str.strip, line.split('='))
                self.config_data[current_section][key] = value

    def set_general_values(self):
        general = self.config_data.get('general', {})
        self.gaps_in.setValue(int(general.get('gaps_in', 0)))
        self.gaps_out.setValue(int(general.get('gaps_out', 0)))
        self.border_size.setValue(int(general.get('border_size', 0)))
        self.active_border_color.setColor(general.get('col.active_border', '#FFFFFF'))
        self.inactive_border_color.setColor(general.get('col.inactive_border', '#CCCCCC'))
        self.layout.setCurrentText(general.get('layout', 'dwindle'))

    def color_to_rgb(self, color):
        return f'rgb({color.name()[1:]})'

    def save_config(self):
        with open(self.config_path, 'r') as f:
            lines = f.readlines()

        updated_lines = []
        in_general_section = False
        general_options = {
            'gaps_in': self.gaps_in.value(),
            'gaps_out': self.gaps_out.value(),
            'border_size': self.border_size.value(),
            'col.active_border': self.color_to_rgb(self.active_border_color.color),
            'col.inactive_border': self.color_to_rgb(self.inactive_border_color.color),
            'layout': self.layout.currentText()
        }

        for line in lines:
            if line.strip() == 'general {':
                in_general_section = True
                updated_lines.append(line)
            elif line.strip() == '}' and in_general_section:
                in_general_section = False
                updated_lines.append(line)
            elif in_general_section and '=' in line:
                option, current_value = map(str.strip, line.split('='))
                if option in general_options:
                    new_value = str(general_options[option])
                    if new_value != current_value:
                        updated_lines.append(f'    {option} = {new_value}\n')
                    else:
                        updated_lines.append(line)
                else:
                    updated_lines.append(line)
            else:
                updated_lines.append(line)

        with open(self.config_path, 'w') as f:
            f.writelines(updated_lines)

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

        sections = ["Keybinds", "Settings"]
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

        settings_widget = QTabWidget()
        hyprland_conf_widget = HyprlandConfigWidget(os.path.expanduser("~/hyprland/hypr/hyprland.conf"))
        settings_widget.addTab(hyprland_conf_widget, "Hyprland")
        
        hyprpaper_conf_widget = QWidget()
        hyprpaper_conf_layout = QVBoxLayout(hyprpaper_conf_widget)
        self.hyprpaper_conf_edit = ConfigEditor(os.path.expanduser("~/hyprland/hypr/hyprpaper.conf"))
        hyprpaper_conf_scroll_area = CustomScrollArea()
        hyprpaper_conf_scroll_area.setWidget(self.hyprpaper_conf_edit)
        hyprpaper_conf_scroll_area.setWidgetResizable(True)
        self.hyprpaper_conf_status = QLabel("No unsaved changes")
        hyprpaper_conf_layout.addWidget(hyprpaper_conf_scroll_area)
        hyprpaper_conf_layout.addWidget(self.hyprpaper_conf_status)
        settings_widget.addTab(hyprpaper_conf_widget, "Hyprpaper")
        
        self.stack.addWidget(settings_widget)

        for i, btn in enumerate(self.section_buttons):
            btn.clicked.connect(lambda _, idx=i: self.stack.setCurrentIndex(idx))

        self.update_keybinds()

        self.save_shortcut = QShortcut(QKeySequence("Ctrl+S"), self)
        self.save_shortcut.activated.connect(self.save_current_config)
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
        if isinstance(current_widget, QTabWidget):
            current_tab = current_widget.currentWidget()
            if isinstance(current_tab, HyprlandConfigWidget):
                current_tab.save_config()
            elif isinstance(current_tab, QWidget):
                editor = current_tab.findChild(ConfigEditor)
                if editor:
                    editor.save_file()
                    self.update_status(current_tab.findChild(QLabel), editor)

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