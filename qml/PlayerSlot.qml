import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import StremioMultiview 1.0

Rectangle {
    id: root
    color: "#000000"
    border.color: isAudioActive ? "#7B68EE" : "transparent"
    border.width: isMaximumMode ? 0 : (isAudioActive ? 2 : 0)

    property int slotIndex: 0
    property bool isMaximumMode: false
    property bool fillMode: true
    property var slotData: ({})
    property bool isAudioActive: QuadController.activeAudioSlot === slotIndex
    property bool isSolo: QuadController.soloSlot === slotIndex
    property string streamUrl: slotData && slotData.streamUrl ? slotData.streamUrl : ""
    property string title: slotData && slotData.title ? slotData.title : ""
    property string poster: slotData && slotData.poster ? slotData.poster : ""

    signal requestOpenSearch(int slot)

    // Global Play/Pause listener in slot scope
    Connections {
        target: QuadController
        function onPlayPauseAllRequested(pause) {
            if (playerLoader.item) {
                if (pause) playerLoader.item.pause()
                else playerLoader.item.play()
            }
        }
    }

    // Hardware-accelerated Video Player
    Loader {
        id: playerLoader
        anchors.fill: parent
        active: root.streamUrl !== ""
        sourceComponent: Component {
            MpvItem {
                id: playerInstance
                anchors.fill: parent
                source: root.streamUrl
                muted: !root.isAudioActive
                fillMode: root.fillMode
            }
        }
    }

    // Buffering Spinner
    BusyIndicator {
        anchors.centerIn: parent
        visible: root.streamUrl !== "" && (!playerLoader.item || (playerLoader.item.position === 0 && !playerLoader.item.isPaused))
        running: visible
        z: 2
    }

    // Empty State (Initial screen when no stream is loaded)
    Rectangle {
        anchors.fill: parent
        color: (hoverArea.containsMouse && root.streamUrl === "") ? "#14141f" : "#0d0d12"
        visible: root.streamUrl === ""
        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 56; height: 56
                radius: 28
                color: hoverArea.containsMouse ? "#28283a" : "#1a1a24"
                border.color: hoverArea.containsMouse ? "#7B68EE" : "#2f2f3e"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: (root.slotIndex + 1).toString()
                    color: "#7B68EE"
                    font.bold: true
                    font.pixelSize: 24
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Slot " + (root.slotIndex + 1)
                color: hoverArea.containsMouse ? "#ffffff" : "#8e8ea0"
                font.pixelSize: 15
                font.bold: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                StyledButton {
                    text: "+ Search"
                    primary: true
                    customRadius: 8
                    onClicked: (mouse) => { root.requestOpenSearch(root.slotIndex) }
                }

                Item {
                    Layout.preferredWidth: emptyHistBtn.implicitWidth
                    Layout.preferredHeight: emptyHistBtn.implicitHeight

                    StyledButton {
                        id: emptyHistBtn
                        anchors.fill: parent
                        text: "History ▾"
                        customRadius: 8
                        onClicked: (mouse) => { emptyHistoryMenu.open() }
                    }

                    // Browser-Style History Dropdown Menu on Empty Slot
                    Popup {
                        id: emptyHistoryMenu
                        y: parent.height + 4
                        x: -80
                        width: 280
                        padding: 4
                        modal: false
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        background: Rectangle {
                            color: "#14141e"
                            radius: 8
                            border.color: "#2e2e42"
                            border.width: 1
                        }

                        contentItem: ColumnLayout {
                            spacing: 2

                            Text {
                                visible: !QuadController.historyList || QuadController.historyList.length === 0
                                text: "No watched history yet"
                                color: "#707085"
                                font.pixelSize: 11
                                padding: 8
                            }

                            ListView {
                                id: emptyHistList
                                Layout.preferredWidth: 272
                                Layout.preferredHeight: Math.min(260, count * 32)
                                clip: true
                                model: QuadController.historyList
                                visible: count > 0

                                delegate: Rectangle {
                                    width: emptyHistList.width
                                    height: 32
                                    radius: 4
                                    color: emptyHistItemMouse.containsMouse ? "#26263a" : "transparent"

                                    MouseArea {
                                        id: emptyHistItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            QuadController.loadStream(root.slotIndex, modelData.title || "Stream", modelData.poster || "", modelData.streamUrl || "")
                                            emptyHistoryMenu.close()
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredWidth: 16
                                                Layout.preferredHeight: 20
                                                radius: 2
                                                color: "#222232"

                                                Image {
                                                    id: miniPoster1
                                                    anchors.fill: parent
                                                    source: modelData.poster || ""
                                                    asynchronous: true
                                                    fillMode: Image.PreserveAspectCrop
                                                    visible: status === Image.Ready && source !== ""
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "🎬"
                                                    font.pixelSize: 9
                                                    visible: miniPoster1.status !== Image.Ready
                                                }
                                            }

                                            Text {
                                                text: modelData.title || "Untitled"
                                                color: emptyHistItemMouse.containsMouse ? "#ffffff" : "#d0d0e0"
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Hoverable Interactive Overlay
    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: (root.streamUrl === "") ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (root.streamUrl === "") {
                root.requestOpenSearch(root.slotIndex)
            } else {
                if (mouse.button === Qt.LeftButton) {
                    QuadController.activeAudioSlot = root.slotIndex
                }
            }
        }

        onDoubleClicked: (mouse) => {
            if (root.streamUrl !== "") {
                QuadController.soloSlot = (QuadController.soloSlot === root.slotIndex) ? -1 : root.slotIndex
            } else {
                root.requestOpenSearch(root.slotIndex)
            }
        }

        // Top Status Header
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 48
            color: Qt.rgba(12/255, 12/255, 18/255, 0.88)
            border.color: "#222230"
            border.width: 1
            visible: (hoverArea.containsMouse || root.isAudioActive) && root.streamUrl !== "" && !root.isMaximumMode

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    width: 28; height: 28
                    radius: 14
                    color: root.isAudioActive ? "#7B68EE" : "#2a2a3a"

                    Text {
                        anchors.centerIn: parent
                        text: (root.slotIndex + 1).toString()
                        color: "white"
                        font.bold: true
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    visible: root.isAudioActive
                    width: 66; height: 24
                    radius: 6
                    color: "#7B68EE"

                    Text {
                        anchors.centerIn: parent
                        text: "🔊 AUDIO"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 10
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title ? root.title : ("Slot " + (root.slotIndex + 1))
                    color: "white"
                    font.bold: true
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Item {
                    Layout.preferredWidth: activeHistBtn.implicitWidth
                    Layout.preferredHeight: activeHistBtn.implicitHeight

                    StyledButton {
                        id: activeHistBtn
                        anchors.fill: parent
                        text: "History ▾"
                        customRadius: 8
                        onClicked: (mouse) => { activeHistoryMenu.open() }
                    }

                    // Browser-Style History Dropdown Menu on Active Slot
                    Popup {
                        id: activeHistoryMenu
                        y: parent.height + 4
                        x: -120
                        width: 280
                        padding: 4
                        modal: false
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        background: Rectangle {
                            color: "#14141e"
                            radius: 8
                            border.color: "#2e2e42"
                            border.width: 1
                        }

                        contentItem: ColumnLayout {
                            spacing: 2

                            Text {
                                visible: !QuadController.historyList || QuadController.historyList.length === 0
                                text: "No watched history yet"
                                color: "#707085"
                                font.pixelSize: 11
                                padding: 8
                            }

                            ListView {
                                id: activeHistList
                                Layout.preferredWidth: 272
                                Layout.preferredHeight: Math.min(260, count * 32)
                                clip: true
                                model: QuadController.historyList
                                visible: count > 0

                                delegate: Rectangle {
                                    width: activeHistList.width
                                    height: 32
                                    radius: 4
                                    color: activeHistItemMouse.containsMouse ? "#26263a" : "transparent"

                                    MouseArea {
                                        id: activeHistItemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            QuadController.loadStream(root.slotIndex, modelData.title || "Stream", modelData.poster || "", modelData.streamUrl || "")
                                            activeHistoryMenu.close()
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Rectangle {
                                                Layout.preferredWidth: 16
                                                Layout.preferredHeight: 20
                                                radius: 2
                                                color: "#222232"

                                                Image {
                                                    id: miniPoster2
                                                    anchors.fill: parent
                                                    source: modelData.poster || ""
                                                    asynchronous: true
                                                    fillMode: Image.PreserveAspectCrop
                                                    visible: status === Image.Ready && source !== ""
                                                }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "🎬"
                                                    font.pixelSize: 9
                                                    visible: miniPoster2.status !== Image.Ready
                                                }
                                            }

                                            Text {
                                                text: modelData.title || "Untitled"
                                                color: activeHistItemMouse.containsMouse ? "#ffffff" : "#d0d0e0"
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                StyledButton {
                    text: "Change"
                    visible: root.streamUrl !== ""
                    onClicked: (mouse) => { root.requestOpenSearch(root.slotIndex) }
                }

                StyledButton {
                    text: root.isSolo ? "🗗 2x2" : "🗖 Solo"
                    primary: !root.isSolo
                    onClicked: (mouse) => { QuadController.soloSlot = root.isSolo ? -1 : root.slotIndex }
                }
            }
        }

        // Bottom Controls Bar (Timeline & Playback)
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 52
            color: Qt.rgba(12/255, 12/255, 18/255, 0.90)
            border.color: "#222230"
            border.width: 1
            visible: hoverArea.containsMouse && root.streamUrl !== ""

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                StyledButton {
                    text: (playerLoader.item && playerLoader.item.isPaused) ? "▶ Play" : "❚❚ Pause"
                    customRadius: 8
                    onClicked: (mouse) => {
                        if (playerLoader.item) playerLoader.item.togglePause()
                    }
                }

                StyledSlider {
                    id: scrubSlider
                    Layout.fillWidth: true
                    from: 0
                    to: (playerLoader.item && playerLoader.item.duration > 0) ? playerLoader.item.duration : 100
                    value: playerLoader.item ? playerLoader.item.position : 0
                    onMoved: {
                        if (playerLoader.item) playerLoader.item.seek(value)
                    }
                }

                Text {
                    text: formatTime(playerLoader.item ? playerLoader.item.position : 0) + " / " + formatTime(playerLoader.item ? playerLoader.item.duration : 0)
                    color: "#a0a0b8"
                    font.pixelSize: 11
                    font.bold: true
                }

                StyledButton {
                    text: root.isAudioActive ? "🔊 Active" : "🔇 Mute"
                    activePill: root.isAudioActive
                    onClicked: (mouse) => { QuadController.activeAudioSlot = root.slotIndex }
                }
            }
        }
    }

    function formatTime(seconds) {
        var sec = Math.floor(seconds % 60)
        var min = Math.floor((seconds / 60) % 60)
        var hr = Math.floor(seconds / 3600)
        var sSec = sec < 10 ? "0" + sec : sec
        var sMin = min < 10 ? "0" + min : min
        return hr > 0 ? (hr + ":" + sMin + ":" + sSec) : (sMin + ":" + sSec)
    }
}
