import sys
import os
import re
from PyQt6.QtWidgets import (QApplication, QMainWindow, QTableWidget, QTableWidgetItem, 
                             QVBoxLayout, QHBoxLayout, QWidget, QPushButton, QStackedWidget, 
                             QTextEdit, QScrollBar, QScrollArea, QLabel, QPlainTextEdit, 
                             QCheckBox, QSpinBox, QComboBox, QColorDialog, QTabWidget,
                             QScrollArea, QFormLayout, QGroupBox, QLineEdit, QInputDialog, QMessageBox,
                             QDoubleSpinBox)
from PyQt6.QtGui import (QFont, QKeySequence, QShortcut, QColor, QTextFormat, QPainter, QPalette,
                         QSyntaxHighlighter, QTextCharFormat)
from PyQt6.QtCore import Qt, QTimer, QEvent, QRect, pyqtSignal

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
    colorChanged = pyqtSignal(QColor)

    def __init__(self, color=None, parent=None):
        super().__init__(parent)
        self.setFixedSize(32, 32)
        self.color = color or QColor("#FFFFFF")
        self.setColor(self.color)
        self.clicked.connect(self.choose_color)

    def setColor(self, color):
        if isinstance(color, str):
            color = QColor(color)
        if self.color != color:
            self.color = color
            self.setStyleSheet(f"background-color: {self.color.name()}; border: 1px solid #45475A; border-radius: 3px;")
            self.colorChanged.emit(self.color)

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
        self.section_layouts = {}
        self.load_config()
        self.initUI()

    def initUI(self):
        layout = QVBoxLayout()
        self.scroll_area = CustomScrollArea()
        self.scroll_widget = QWidget()
        self.scroll_layout = QFormLayout(self.scroll_widget)
        self.scroll_area.setWidget(self.scroll_widget)
        self.scroll_area.setWidgetResizable(True)
        layout.addWidget(self.scroll_area)

        add_button = QPushButton("Add Option")
        add_button.clicked.connect(self.add_option)
        layout.addWidget(add_button)

        self.setLayout(layout)
        self.update_widgets()

    def load_config(self):
        with open(self.config_path, "r") as f:
            current_section = None
            for line in f:
                line = line.strip()
                if line.startswith("#") or not line:
                    continue
                if line.endswith("{"):
                    current_section = line.split()[0]
                    self.config_data[current_section] = {}
                elif "=" in line and current_section:
                    key, value = line.split("=", 1)
                    self.config_data[current_section][key.strip()] = value.strip()

    def save_config(self):
        with open(self.config_path, "w") as f:
            for section, options in self.config_data.items():
                f.write(f"{section} {{\n")
                for key, value in options.items():
                    f.write(f"    {key} = {value}\n")
                f.write("}\n\n")

    def update_widgets(self):
        for i in reversed(range(self.scroll_layout.rowCount())):
            self.scroll_layout.removeRow(i)
        
        for section, options in self.config_data.items():
            if section not in self.section_layouts:
                self.section_layouts[section] = QFormLayout()
                section_widget = QWidget()
                section_widget.setLayout(self.section_layouts[section])
                self.scroll_layout.addRow(section, section_widget)
            
            for option, value in options.items():
                widget = self.create_widget_for_option(option, value)
                remove_button = QPushButton("Remove")
                remove_button.clicked.connect(lambda _, s=section, o=option: self.remove_option(s, o))
                hbox = QHBoxLayout()
                hbox.addWidget(widget)
                hbox.addWidget(remove_button)
                self.section_layouts[section].addRow(option, hbox)

    def create_widget_for_option(self, option, value):
        if option in ["border_size", "gaps_in", "gaps_out", "gaps_workspaces", "extend_border_grab_area", "resize_corner",
                      "shadow_range", "shadow_render_power", "blur_size", "blur_passes", "workspace_swipe_fingers",
                      "workspace_swipe_distance", "workspace_swipe_min_speed_to_force", "workspace_swipe_cancel_ratio",
                      "workspace_swipe_direction_lock_threshold", "scroll_event_delay"]:
            widget = QSpinBox()
            widget.setRange(0, 1000)
            widget.setValue(int(value))
            widget.valueChanged.connect(lambda v, o=option: self.update_config(o, str(v)))
        elif option in ["no_border_on_floating", "resize_on_border", "hover_icon_on_border", "allow_tearing",
                        "drop_shadow", "shadow_ignore_window", "dim_inactive", "blur_enabled", "blur_ignore_opacity",
                        "blur_new_optimizations", "blur_xray", "blur_special", "blur_popups"]:
            widget = QCheckBox()
            widget.setChecked(value.lower() in ["true", "yes", "on", "1"])
            widget.stateChanged.connect(lambda v, o=option: self.update_config(o, "true" if v else "false"))
        elif option in ["active_opacity", "inactive_opacity", "fullscreen_opacity", "shadow_scale", "dim_strength",
                        "dim_special", "dim_around", "blur_noise", "blur_contrast", "blur_brightness", "blur_vibrancy",
                        "blur_vibrancy_darkness", "sensitivity"]:
            widget = QDoubleSpinBox()
            widget.setRange(0, 1)
            widget.setSingleStep(0.1)
            widget.setValue(float(value))
            widget.valueChanged.connect(lambda v, o=option: self.update_config(o, str(v)))
        elif option in ["col.inactive_border", "col.active_border", "col.nogroup_border", "col.nogroup_border_active",
                        "col.shadow", "col.shadow_inactive"]:
            widget = ColorButton(value)
            widget.colorChanged.connect(lambda c, o=option: self.update_config(o, c.name()))
        else:
            widget = QLineEdit(value)
            widget.textChanged.connect(lambda v, o=option: self.update_config(o, v))
        return widget

    def update_config(self, option, value):
        for section, options in self.config_data.items():
            if option in options:
                self.config_data[section][option] = value
                break

    def add_option(self):
        all_options = {
            "general": ["border_size", "no_border_on_floating", "gaps_in", "gaps_out", "gaps_workspaces",
                        "col.inactive_border", "col.active_border", "col.nogroup_border", "col.nogroup_border_active",
                        "layout", "no_focus_fallback", "resize_on_border", "extend_border_grab_area",
                        "hover_icon_on_border", "allow_tearing", "resize_corner"],
            "decoration": ["rounding", "active_opacity", "inactive_opacity", "fullscreen_opacity", "drop_shadow",
                           "shadow_range", "shadow_render_power", "shadow_ignore_window", "col.shadow",
                           "col.shadow_inactive", "shadow_offset", "shadow_scale", "dim_inactive", "dim_strength",
                           "dim_special", "dim_around", "screen_shader"],
            "animations": ["enabled", "first_launch_animation"],
            "input": ["kb_model", "kb_layout", "kb_variant", "kb_options", "kb_rules", "kb_file",
                      "numlock_by_default", "resolve_binds_by_sym", "repeat_rate", "repeat_delay",
                      "sensitivity", "accel_profile", "force_no_accel", "left_handed", "scroll_method",
                      "natural_scroll", "follow_mouse", "mouse_refocus", "float_switch_override_focus"],
            "gestures": ["workspace_swipe", "workspace_swipe_fingers", "workspace_swipe_distance",
                         "workspace_swipe_invert", "workspace_swipe_min_speed_to_force",
                         "workspace_swipe_cancel_ratio", "workspace_swipe_create_new",
                         "workspace_swipe_direction_lock", "workspace_swipe_direction_lock_threshold"],
            "misc": ["disable_hyprland_logo", "disable_splash_rendering", "vfr", "vrr", "mouse_move_enables_dpms",
                     "always_follow_on_dnd", "layers_hog_keyboard_focus", "animate_manual_resizes",
                     "disable_autoreload", "enable_swallow", "swallow_regex", "focus_on_activate",
                     "no_direct_scanout", "hide_cursor_on_touch", "mouse_move_focuses_monitor"],
            "binds": ["pass_mouse_when_bound", "scroll_event_delay", "workspace_back_and_forth",
                      "allow_workspace_cycles", "focus_preferred_method"],
            "xwayland": ["use_nearest_neighbor", "force_zero_scaling"],
            "debug": ["overlay", "damage_blink", "disable_logs", "disable_time", "damage_tracking",
                      "enable_stdout_logs", "manual_crash", "suppress_errors"]
        }

        available_options = []
        for section, options in all_options.items():
            for option in options:
                if option not in self.config_data.get(section, {}):
                    available_options.append(f"{section}:{option}")

        dialog = QInputDialog(self)
        dialog.setComboBoxItems(available_options)
        dialog.setWindowTitle("Add Option")
        dialog.setLabelText("Select an option to add:")
        dialog.resize(400, 300)
        dialog.findChild(QComboBox).setMaxVisibleItems(10)

        if dialog.exec() == QInputDialog.Accepted:
            selected = dialog.textValue()
            if selected:
                section, option = selected.split(':')
                default_value = self.get_default_value(option)
                widget = self.create_widget_for_option(option, default_value)
                
                remove_button = QPushButton("Remove")
                remove_button.clicked.connect(lambda _, s=section, o=option: self.remove_option(s, o))
                
                hbox = QHBoxLayout()
                hbox.addWidget(widget)
                hbox.addWidget(remove_button)
                
                if section not in self.config_data:
                    self.config_data[section] = {}
                self.config_data[section][option] = default_value
                
                if section not in self.section_layouts:
                    self.section_layouts[section] = QFormLayout()
                    section_widget = QWidget()
                    section_widget.setLayout(self.section_layouts[section])
                    self.scroll_layout.addRow(section, section_widget)
                
                self.section_layouts[section].addRow(option, hbox)

    def remove_option(self, section, option):
        if section in self.config_data and option in self.config_data[section]:
            del self.config_data[section][option]
            for i in range(self.section_layouts[section].rowCount()):
                if self.section_layouts[section].itemAt(i, QFormLayout.LabelRole).widget().text() == option:
                    self.section_layouts[section].removeRow(i)
                    break

    def get_default_value(self, option):
        if option in ["border_size", "gaps_in", "gaps_out"]:
            return "5"
        elif option in ["no_border_on_floating", "resize_on_border", "hover_icon_on_border", "allow_tearing"]:
            return "false"
        elif option == "layout":
            return "dwindle"
        elif option == "accel_profile":
            return "adaptive"
        elif option == "scroll_method":
            return "2fg"
        elif option in ["active_opacity", "inactive_opacity", "fullscreen_opacity", "shadow_scale",
                        "dim_strength", "dim_special", "dim_around", "sensitivity"]:
            return "1.0"
        else:
            return ""

class App(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Hyprland Configuration")
        self.setObjectName("HyprlandConfig")
        self.setGeometry(100, 100, 1000, 600)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        layout = QVBoxLayout(central_widget)

        settings_widget = QTabWidget()

        keybinds_widget = QWidget()
        keybinds_layout = QVBoxLayout(keybinds_widget)
        self.keybinds_table = QTableWidget()
        self.keybinds_table.setColumnCount(2)
        self.keybinds_table.setHorizontalHeaderLabels(["Keybind", "Description"])
        self.keybinds_table.horizontalHeader().setStretchLastSection(True)
        self.keybinds_table.verticalHeader().setVisible(False)
        self.keybinds_table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.keybinds_table.setSelectionMode(QTableWidget.SelectionMode.NoSelection)
        self.keybinds_table.setFocusPolicy(Qt.FocusPolicy.NoFocus)
        keybinds_layout.addWidget(self.keybinds_table)
        settings_widget.addTab(keybinds_widget, "Keybinds")

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

        layout.addWidget(settings_widget)

        self.save_shortcut = QShortcut(QKeySequence("Ctrl+S"), self)
        self.save_shortcut.activated.connect(self.save_current_config)
        self.hyprpaper_conf_edit.textChanged.connect(lambda: self.update_status(self.hyprpaper_conf_status, self.hyprpaper_conf_edit))

        self.update_keybinds()

    def update_keybinds(self):
        keybinds = parse_keybinds_from_readme()
        self.keybinds_table.setRowCount(len(keybinds))
        for row, (keybind, description) in enumerate(keybinds):
            self.keybinds_table.setItem(row, 0, QTableWidgetItem(keybind))
            self.keybinds_table.setItem(row, 1, QTableWidgetItem(description))
        self.keybinds_table.resizeColumnsToContents()

    def save_current_config(self):
        current_widget = self.centralWidget().layout().itemAt(0).widget().currentWidget()
        if isinstance(current_widget, HyprlandConfigWidget):
            current_widget.save_config()
        elif isinstance(current_widget, QWidget):
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