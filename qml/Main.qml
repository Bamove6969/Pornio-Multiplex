import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import StremioMultiview 1.0

Window {
    id: mainWindow
    width: 1600
    height: 900
    visible: true
    title: "Stremio Multiview 4-Screen"
    color: "#08080c"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // App Top Bar
        Rectangle {
            Layout.fillWidth: true
            height: 48
            color: "#111118"
            border.color: "#1e1e28"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                Text {
                    text: "STREMIO MULTIVIEW"
                    color: "#7B68EE"
                    font.bold: true
                    font.pixelSize: 15
                }

                Rectangle {
                    width: 1; height: 24; color: "#2d2d3c"
                }

                Text {
                    text: "Audio Focus: Slot " + (QuadController.activeAudioSlot + 1) + " (Keys: 1, 2, 3, 4)"
                    color: "#a0a0b8"
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Slot 1"
                    highlighted: QuadController.activeAudioSlot === 0
                    onClicked: QuadController.activeAudioSlot = 0
                }
                Button {
                    text: "Slot 2"
                    highlighted: QuadController.activeAudioSlot === 1
                    onClicked: QuadController.activeAudioSlot = 1
                }
                Button {
                    text: "Slot 3"
                    highlighted: QuadController.activeAudioSlot === 2
                    onClicked: QuadController.activeAudioSlot = 2
                }
                Button {
                    text: "Slot 4"
                    highlighted: QuadController.activeAudioSlot === 3
                    onClicked: QuadController.activeAudioSlot = 3
                }

                Button {
                    text: "Play/Pause All (Space)"
                    onClicked: QuadController.togglePlayPauseAll()
                }

                Button {
                    text: mainWindow.visibility === Window.FullScreen ? "🗗 Window" : "🗖 Fullscreen (F11)"
                    onClicked: {
                        mainWindow.visibility = (mainWindow.visibility === Window.FullScreen) ? Window.Windowed : Window.FullScreen
                    }
                }
            }
        }

        // 2x2 Viewport Area
        QuadGrid {
            id: quadGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            onRequestOpenSearch: (slot) => {
                searchDialog.openForSlot(slot)
            }
        }
    }

    // Stream Search Modal
    SearchDialog {
        id: searchDialog
    }

    // Global Keybindings
    Shortcut { sequence: "1"; onActivated: QuadController.activeAudioSlot = 0 }
    Shortcut { sequence: "2"; onActivated: QuadController.activeAudioSlot = 1 }
    Shortcut { sequence: "3"; onActivated: QuadController.activeAudioSlot = 2 }
    Shortcut { sequence: "4"; onActivated: QuadController.activeAudioSlot = 3 }
    
    Shortcut { sequence: "Ctrl+1"; onActivated: searchDialog.openForSlot(0) }
    Shortcut { sequence: "Ctrl+2"; onActivated: searchDialog.openForSlot(1) }
    Shortcut { sequence: "Ctrl+3"; onActivated: searchDialog.openForSlot(2) }
    Shortcut { sequence: "Ctrl+4"; onActivated: searchDialog.openForSlot(3) }

    Shortcut { sequence: "Escape"; onActivated: QuadController.soloSlot = -1 }
    Shortcut { sequence: "Space"; onActivated: QuadController.togglePlayPauseAll() }
    Shortcut {
        sequence: "F11"
        onActivated: {
            mainWindow.visibility = (mainWindow.visibility === Window.FullScreen) ? Window.Windowed : Window.FullScreen
        }
    }
}
