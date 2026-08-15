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
    title: "Pornio-Multiplex"
    color: "#000000"

    property bool isMaximumMode: false
    property bool globalFillMode: true

    Item {
        anchors.fill: parent

        // 2x2 Viewport Area (100% full screen real estate, zero bezel, zero gap)
        QuadGrid {
            id: quadGrid
            anchors.fill: parent
            isMaximumMode: mainWindow.isMaximumMode
            onRequestOpenSearch: (slot) => {
                searchDialog.openForSlot(slot)
            }
        }

        // Top Control Bar (Slides down from top edge on hover in Maximum mode)
        Rectangle {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
            color: Qt.rgba(14/255, 14/255, 20/255, 0.95)
            border.color: "#1e1e28"
            border.width: 1
            z: 100

            visible: opacity > 0
            opacity: (!mainWindow.isMaximumMode || topHoverZone.containsMouse || topBarHover.containsMouse) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

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
                    text: "PORNIO-MULTIPLEX"
                    color: "#7B68EE"
                    font.bold: true
                    font.pixelSize: 14
                }

                Rectangle {
                    width: 1; height: 20; color: "#2d2d3c"
                }

                Text {
                    text: "Audio: Slot " + (QuadController.activeAudioSlot + 1) + " (Keys: 1, 2, 3, 4)"
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
                    text: "Play/Pause (Space)"
                    onClicked: (mouse) => { QuadController.togglePlayPauseAll() }
                }

                Button {
                    text: mainWindow.isMaximumMode ? "🗗 Standard (M)" : "⚡ Maximum View (M)"
                    highlighted: mainWindow.isMaximumMode
                    onClicked: (mouse) => {
                        toggleMaximumMode()
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

        // Top-edge hover trigger for auto-revealing control bar in Maximum mode
        MouseArea {
            id: topHoverZone
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 12
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            z: 99
        }
    }

    // Stream Search Modal
    SearchDialog {
        id: searchDialog
    }

    function toggleMaximumMode() {
        mainWindow.isMaximumMode = !mainWindow.isMaximumMode
        if (mainWindow.isMaximumMode) {
            mainWindow.visibility = Window.FullScreen
        } else {
            mainWindow.visibility = Window.Windowed
        }
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
        onActivated: toggleMaximumMode()
    }
    Shortcut { 
        sequence: "F10"
        onActivated: toggleMaximumMode()
    }

    Shortcut { 
        sequence: "Escape"
        onActivated: {
            if (QuadController.soloSlot !== -1) {
                QuadController.soloSlot = -1
            } else if (mainWindow.isMaximumMode) {
                toggleMaximumMode()
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
