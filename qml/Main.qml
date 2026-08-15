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

        // Top Control Bar (Frosted glass overlay, slides down from top edge on hover in Maximum mode)
        Rectangle {
            id: topBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52
            color: Qt.rgba(13/255, 13/255, 19/255, 0.94)
            border.color: "#222232"
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
                anchors.margins: 10
                spacing: 10

                // App Brand Badge
                Rectangle {
                    width: 32; height: 32
                    radius: 8
                    color: "#7B68EE"

                    Text {
                        anchors.centerIn: parent
                        text: "4X"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 13
                    }
                }

                Text {
                    text: "PORNIO MULTIPLEX"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                }

                Rectangle {
                    width: 1; height: 22; color: "#2d2d3e"
                }

                // Live Audio Focus Tag
                Rectangle {
                    height: 26
                    width: audioFocusText.implicitWidth + 20
                    radius: 6
                    color: "#1c1c28"
                    border.color: "#7B68EE"
                    border.width: 1

                    Text {
                        id: audioFocusText
                        anchors.centerIn: parent
                        text: "🔊 Audio: Slot " + (QuadController.activeAudioSlot + 1)
                        color: "#9D8FFF"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

                // Slot Audio Selectors
                StyledButton {
                    text: "Slot 1"
                    activePill: QuadController.activeAudioSlot === 0
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 0 }
                }
                StyledButton {
                    text: "Slot 2"
                    activePill: QuadController.activeAudioSlot === 1
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 1 }
                }
                StyledButton {
                    text: "Slot 3"
                    activePill: QuadController.activeAudioSlot === 2
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 2 }
                }
                StyledButton {
                    text: "Slot 4"
                    activePill: QuadController.activeAudioSlot === 3
                    onClicked: (mouse) => { QuadController.activeAudioSlot = 3 }
                }

                Rectangle {
                    width: 1; height: 22; color: "#2d2d3e"
                }

                StyledButton {
                    text: "❚❚ Play/Pause (Space)"
                    onClicked: (mouse) => { QuadController.togglePlayPauseAll() }
                }

                StyledButton {
                    text: mainWindow.isMaximumMode ? "🗗 Standard View (M)" : "⚡ Maximum View (M)"
                    primary: !mainWindow.isMaximumMode
                    onClicked: (mouse) => {
                        toggleMaximumMode()
                    }
                }

                StyledButton {
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
