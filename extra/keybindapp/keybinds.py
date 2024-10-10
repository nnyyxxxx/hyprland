import sys
import os
from PyQt6.QtWidgets import QApplication, QMainWindow, QTableWidget, QTableWidgetItem, QVBoxLayout, QWidget
from PyQt6.QtGui import QFont
from PyQt6.QtCore import Qt

class KeybindsApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Hyprland Keybinds")
        self.setObjectName("HyprlandKeybinds")

        central_widget = QWidget()
        self.setCentralWidget(central_widget)

        layout = QVBoxLayout(central_widget)

        table = QTableWidget()
        table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        table.setFocusPolicy(Qt.FocusPolicy.NoFocus)
        table.setSelectionMode(QTableWidget.SelectionMode.NoSelection)
        table.setColumnCount(2)
        table.setHorizontalHeaderLabels(["Keybind", "Description"])
        table.horizontalHeader().setStretchLastSection(True)
        table.verticalHeader().setVisible(False)

        keybinds = [
            ("ALT SHIFT + Enter", "Spawns kitty (Terminal)"),
            ("ALT SHIFT + P", "Spawns rofi (Application launcher)"),
            ("ALT SHIFT + C", "Kills current window"),
            ("ALT SHIFT + W", "Kills hyprland"),
            ("ALT SHIFT + F", "Toggles fullscreen"),
            ("ALT SHIFT + V", "Spawns hyprpicker (Color picker)"),
            ("ALT SHIFT + B", "Reloads waybar / Spawns waybar"),
            ("ALT SHIFT + K", "Opens the keybinds app (or just click the notebook button in waybar)"),
            ("ALT + ESC", "Spawns grim (Screenshot utility)"),
            ("ALT + LMB", "Drags selected window"),
            ("ALT + RMB", "Resizes window in floating & resizes mfact in tiled; when two or more windows are on screen"),
            ("ALT + SPACE", "Makes the selected window float"),
        ]

        table.setRowCount(len(keybinds))

        for row, (keybind, description) in enumerate(keybinds):
            table.setItem(row, 0, QTableWidgetItem(keybind))
            table.setItem(row, 1, QTableWidgetItem(description))

        table.resizeColumnsToContents()
        table.setFont(QFont("JetBrainsMono Nerd Font", 12))

        layout.addWidget(table)

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