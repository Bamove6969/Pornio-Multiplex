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
    color: "#000000"

    property bool isMaximumMode: false

    Item {
        anchors.fill: parent

        // 2x2 Viewport Area (Takes 100% full screen real estate in Maximum Mode)
        QuadGrid {
            id: quadGrid
            anchors.fill: parent
            anchors.topMargin: (mainWindow.isMaximumMode || topBar.opacity === 0) ? 0 : topBar.height
            isMaximumMode: mainWindow.isMaximumMode
            onRequestOpenSearch: (slot) => {
                searchDialog.openForSlot(slot)
            }
        }

        // Top Control Bar (Collapsible in Maximum Mode, slides down on top-edge hover)
        Rectangle {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
            color: Qt.rgba(17/255, 17/255, 24/255, 0.95)
            border.color: "#1e1e28"
            border.width: 1
            z: 100

            visible: opacity > 0
            opacity: (!mainWindow.isMaximumMode || topHoverZone.containsMouse || topBarHover.containsMouse) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                id: topBarHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Text {
                    text: "STREMIO MULTIVIEW"
                    color: "#7B68EE"
                    font.bold: true
                    font.pixelSize: 14
                }

                Rectangle {
                    width: 1; height: 20; color: "#2d2d3c"
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
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 0 }
                }
                Button {
                    text: "Slot 2"
                    highlighted: QuadController.activeAudioSlot === 1
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 1 }
                }
                Button {
                    text: "Slot 3"
                    highlighted: QuadController.activeAudioSlot === 2
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 2 }
                }
                Button {
                    text: "Slot 4"
                    highlighted: QuadController.activeAudioSlot === 3
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 3 }
                }

                Button {
                    text: "Play/Pause All (Space)"
                    onClicked: (mouse) => { QuadController.togglePlayPauseAll() }
                }

                Button {
                    text: mainWindow.isMaximumMode ? "🗗 Standard View (M)" : "⚡ Maximum View (M)"
                    highlighted: mainWindow.isMaximumMode
                    onClicked: (mouse) => {
                        mainWindow.isMaximumMode = !mainWindow.isMaximumMode
                    }
                }

                Button {
                    text: mainWindow.visibility === Window.FullScreen ? "🗗 Windowed" : "🗖 Fullscreen (F11)"
                    onClicked: (mouse) => {
                        mainWindow.visibility = (mainWindow.visibility === Window.FullScreen) ? Window.Windowed : Window.FullScreen
                    }
                }
            }
        }

        // Top-edge hover trigger for revealing controls in Maximum Mode
        MouseArea {
            id: topHoverZone
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 10
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 99
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

    Shortcut { 
        sequence: "M"
        onActivated: mainWindow.isMaximumMode = !mainWindow.isMaximumMode 
    }
    Shortcut { 
        sequence: "F10"
        onActivated: mainWindow.isMaximumMode = !mainWindow.isMaximumMode 
    }

    Shortcut { 
        sequence: "Escape"
        onActivated: {
            if (QuadController.soloSlot !== -1) {
                QuadController.soloSlot = -1
            } else if (mainWindow.isMaximumMode) {
                mainWindow.isMaximumMode = false
            }
        }
    }
    
    Shortcut { sequence: "Space"; onActivated: QuadController.togglePlayPauseAll() }
    Shortcut {
        sequence: "F11"
        onActivated: {
            mainWindow.visibility = (mainWindow.visibility === Window.FullScreen) ? Window.Windowed : Window.FullScreen
        }
    }
}
