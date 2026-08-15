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
        color: (hoverArea.containsMouse && root.streamUrl === "") ? "#161622" : "#0d0d12"
        visible: root.streamUrl === ""
        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64; height: 64
                radius: 32
                color: hoverArea.containsMouse ? "#28283a" : "#1a1a24"
                border.color: hoverArea.containsMouse ? "#7B68EE" : "#2f2f3e"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: (root.slotIndex + 1).toString()
                    color: "#7B68EE"
                    font.bold: true
                    font.pixelSize: 26
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Slot " + (root.slotIndex + 1)
                color: hoverArea.containsMouse ? "#ffffff" : "#8e8ea0"
                font.pixelSize: 16
                font.bold: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                StyledButton {
                    text: "+ Search Movies"
                    primary: true
                    customRadius: 10
                    onClicked: (mouse) => { root.requestOpenSearch(root.slotIndex) }
                }

                StyledButton {
                    text: "🕒 Watched History ▾"
                    customRadius: 10
                    onClicked: (mouse) => { historyPopup.open() }
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

                StyledButton {
                    text: "🕒 History ▾"
                    onClicked: (mouse) => { historyPopup.open() }
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

    // Collective Shared Watched Movies History Dropdown
    Popup {
        id: historyPopup
        width: Math.min(380, root.width - 24)
        height: Math.min(360, root.height - 24)
        x: Math.max(12, Math.min(root.width - width - 12, (root.width - width) / 2))
        y: Math.max(12, Math.min(root.height - height - 12, (root.height - height) / 2))
        modal: true
        focus: true

        background: Rectangle {
            color: "#13131d"
            radius: 14
            border.color: "#2f2f45"
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 4

                Rectangle {
                    width: 24; height: 24
                    radius: 6
                    color: "#7B68EE"

                    Text {
                        anchors.centerIn: parent
                        text: (root.slotIndex + 1).toString()
                        color: "white"
                        font.bold: true
                        font.pixelSize: 12
                    }
                }

                Text {
                    text: "Quick Play on Slot " + (root.slotIndex + 1)
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                StyledButton {
                    text: "✕"
                    customRadius: 6
                    onClicked: (mouse) => { historyPopup.close() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#222232"
            }

            // Empty History Message
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !QuadController.historyList || QuadController.historyList.length === 0
                color: "transparent"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "🎬 No Watched Movies Yet"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Play any movie from search once, and it will be saved here so you can instantly auto-play it anytime!"
                        color: "#8e8ea0"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 260
                    }

                    StyledButton {
                        Layout.alignment: Qt.AlignHCenter
                        text: "+ Search Movies Now"
                        primary: true
                        onClicked: (mouse) => {
                            historyPopup.close()
                            root.requestOpenSearch(root.slotIndex)
                        }
                    }
                }
            }

            // History Items List
            ListView {
                id: historyListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: QuadController.historyList && QuadController.historyList.length > 0
                model: QuadController.historyList

                delegate: Rectangle {
                    width: historyListView.width
                    height: 56
                    radius: 8
                    color: historyItemMouse.containsMouse ? "#242438" : "#181826"
                    border.color: historyItemMouse.containsMouse ? "#7B68EE" : "#1f1f2e"
                    border.width: 1

                    MouseArea {
                        id: historyItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: (mouse) => {
                            QuadController.loadStream(
                                root.slotIndex,
                                modelData.title || "Stream",
                                modelData.poster || "",
                                modelData.streamUrl || ""
                            )
                            historyPopup.close()
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 40
                                radius: 4
                                color: "#242436"

                                Image {
                                    id: histImg
                                    anchors.fill: parent
                                    source: modelData.poster || ""
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready && source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "🎬"
                                    font.pixelSize: 16
                                    visible: histImg.status !== Image.Ready
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.title || "Untitled"
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.timestamp ? ("Watched " + modelData.timestamp) : "Recently Watched"
                                    color: "#8e8ea0"
                                    font.pixelSize: 10
                                }
                            }

                            StyledButton {
                                text: "▶ Play"
                                success: true
                                customRadius: 6
                                onClicked: (mouse) => {
                                    QuadController.loadStream(
                                        root.slotIndex,
                                        modelData.title || "Stream",
                                        modelData.poster || "",
                                        modelData.streamUrl || ""
                                    )
                                    historyPopup.close()
                                }
                            }
                        }
                    }
                }
            }

            // Bottom Clear Button
            StyledButton {
                Layout.fillWidth: true
                text: "🗑 Clear Watched History"
                visible: QuadController.historyList && QuadController.historyList.length > 0
                customRadius: 8
                onClicked: (mouse) => {
                    QuadController.clearHistory()
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
