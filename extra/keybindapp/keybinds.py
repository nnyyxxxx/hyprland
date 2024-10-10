import sys
import os
import re
from PyQt6.QtWidgets import QApplication, QMainWindow, QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget
from PyQt6.QtGui import QFont
from PyQt6.QtCore import Qt

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

class KeybindsApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Hyprland Keybinds")
        self.setObjectName("HyprlandKeybinds")
        self.setGeometry(100, 100, 800, 600)

        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        layout = QVBoxLayout(central_widget)

        self.table = QTableWidget()
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setFocusPolicy(Qt.FocusPolicy.NoFocus)
        self.table.setSelectionMode(QTableWidget.SelectionMode.NoSelection)
        self.table.setColumnCount(2)
        self.table.setHorizontalHeaderLabels(["Keybind", "Description"])
        self.table.horizontalHeader().setStretchLastSection(True)
        self.table.verticalHeader().setVisible(False)

        self.update_keybinds()

        self.table.resizeColumnsToContents()
        self.table.setFont(QFont("JetBrainsMono Nerd Font", 12))

        layout.addWidget(self.table)

    def update_keybinds(self):
        keybinds = parse_keybinds_from_readme()
        self.table.setRowCount(len(keybinds))
        for row, (keybind, description) in enumerate(keybinds):
            self.table.setItem(row, 0, QTableWidgetItem(keybind))
            self.table.setItem(row, 1, QTableWidgetItem(description))

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setApplicationName("HyprlandKeybinds")
    app.setDesktopFileName("hyprland-keybinds")
    
    css_path = os.path.expanduser("~/hyprland/extra/keybindapp/styles.css")
    with open(css_path, "r") as f:
        app.setStyleSheet(f.read())
    
    window = KeybindsApp()
    window.show()
    sys.exit(app.exec())