import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: root
    title: "Select Content for Slot " + (targetSlot + 1)
    modal: true
    width: 820
    height: 600
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)

    property int targetSlot: 0
    property var searchResults: []
    property var streamResults: []
    property var selectedMeta: null
    property bool showingStreams: false
    property bool isLoadingStreams: false
    property string activeSource: "backend" // "backend", "cinemeta", "direct"

    background: Rectangle {
        color: "#12121a"
        radius: 14
        border.color: "#28283a"
        border.width: 1
    }

    header: Rectangle {
        height: 56
        color: "#181824"
        radius: 14

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Rectangle {
                width: 32; height: 32
                radius: 8
                color: "#7B68EE"

                Text {
                    anchors.centerIn: parent
                    text: (root.targetSlot + 1).toString()
                    color: "white"
                    font.bold: true
                    font.pixelSize: 14
                }
            }

            Text {
                text: root.showingStreams 
                    ? ("Alternative Streams: " + (root.selectedMeta ? (root.selectedMeta.name || root.selectedMeta.title || "") : "")) 
                    : ("Select Movie for Slot " + (targetSlot + 1))
                color: "white"
                font.bold: true
                font.pixelSize: 15
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            StyledButton {
                text: root.showingStreams ? "← Back to Search" : "✕ Close"
                onClicked: (mouse) => {
                    if (root.showingStreams) {
                        root.showingStreams = false
                        root.isLoadingStreams = false
                    } else {
                        root.close()
                    }
                }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 12

        // Source Switcher Tabs
        RowLayout {
            Layout.fillWidth: true
            visible: !root.showingStreams
            spacing: 8

            StyledButton {
                text: "⚡ Your Backend (RD + Jackett)"
                activePill: root.activeSource === "backend"
                onClicked: (mouse) => {
                    root.activeSource = "backend"
                    loadBackendCatalog()
                }
            }

            StyledButton {
                text: "🎬 Cinemeta (IMDb/TMDB)"
                activePill: root.activeSource === "cinemeta"
                onClicked: (mouse) => {
                    root.activeSource = "cinemeta"
                    root.searchResults = []
                }
            }

            StyledButton {
                text: "🔗 Direct URL / Presets"
                activePill: root.activeSource === "direct"
                onClicked: (mouse) => {
                    root.activeSource = "direct"
                }
            }
        }

        // Search Bar (Backend / Cinemeta)
        RowLayout {
            Layout.fillWidth: true
            visible: !root.showingStreams && root.activeSource !== "direct"
            spacing: 8

            TextField {
                id: searchInput
                Layout.fillWidth: true
                placeholderText: root.activeSource === "backend" ? "Search your Torrent Stream backend..." : "Search Cinemeta (e.g. Inception, Avatar...)"
                color: "white"
                padding: 10
                font.pixelSize: 13
                background: Rectangle {
                    color: "#0a0a0f"
                    radius: 8
                    border.color: searchInput.activeFocus ? "#7B68EE" : "#282838"
                    border.width: 1
                }
                onAccepted: executeSearch()
            }

            ComboBox {
                id: typeCombo
                model: ["movie", "series"]
                currentIndex: 0
                visible: root.activeSource === "cinemeta"
                contentItem: Text {
                    leftPadding: 12
                    rightPadding: 24
                    text: typeCombo.displayText
                    color: "white"
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: "#0a0a0f"
                    radius: 8
                    border.color: "#282838"
                }
            }

            StyledButton {
                text: "🔍 Search"
                primary: true
                onClicked: (mouse) => { executeSearch() }
            }

            StyledButton {
                text: "↻ Refresh"
                visible: root.activeSource === "backend"
                onClicked: (mouse) => { loadBackendCatalog() }
            }
        }

        // Direct URL / Quick Presets Panel
        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.showingStreams && root.activeSource === "direct"
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: directUrlInput
                    Layout.fillWidth: true
                    placeholderText: "Paste direct video link / stream URL (http://...)"
                    color: "white"
                    padding: 10
                    background: Rectangle {
                        color: "#0a0a0f"
                        radius: 8
                        border.color: "#282838"
                    }
                }

                StyledButton {
                    text: "▶ Play on Slot " + (root.targetSlot + 1)
                    success: true
                    onClicked: (mouse) => {
                        if (directUrlInput.text.trim().length > 0) {
                            QuadController.loadStream(root.targetSlot, "Direct URL", "", directUrlInput.text.trim())
                            root.close()
                        }
                    }
                }
            }

            Text {
                text: "Quick Presets (1-Click Test Feeds):"
                color: "#8e8ea0"
                font.pixelSize: 12
                font.bold: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                StyledButton {
                    text: "Big Buck Bunny"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Big Buck Bunny", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
                        root.close()
                    }
                }
                StyledButton {
                    text: "Elephant's Dream"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Elephant's Dream", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")
                        root.close()
                    }
                }
                StyledButton {
                    text: "Tears of Steel"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Tears of Steel", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")
                        root.close()
                    }
                }
                StyledButton {
                    text: "Sintel"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Sintel", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")
                        root.close()
                    }
                }
            }
        }

        // Direct 1-Click Search Results List View
        ListView {
            id: searchListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.showingStreams && root.activeSource !== "direct"
            clip: true
            model: root.searchResults

            delegate: Rectangle {
                id: itemCard
                width: searchListView.width
                height: 74
                color: itemMouse.containsMouse ? "#20202e" : "#14141e"
                radius: 10
                border.color: itemMouse.containsMouse ? "#7B68EE" : "#1f1f2c"
                border.width: 1

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
                        autoPlayItem(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 56
                            color: "#1e1e2c"
                            radius: 6

                            Image {
                                id: posterImg
                                anchors.fill: parent
                                source: (modelData.poster || "")
                                asynchronous: true
                                cache: true
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready && source !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "🎬"
                                font.pixelSize: 20
                                visible: posterImg.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: modelData.name || modelData.title || "Untitled"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (modelData.releaseInfo || modelData.release_info || "") + 
                                      (modelData.imdb_rating ? " • ★ " + modelData.imdb_rating : "") +
                                      (modelData.description ? (" • " + modelData.description) : "")
                                color: "#8e8ea0"
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        StyledButton {
                            text: "▶ Play on Slot " + (root.targetSlot + 1)
                            success: true
                            customRadius: 8
                            onClicked: (mouse) => {
                                autoPlayItem(modelData)
                            }
                        }
                    }
                }
            }
        }

        // Resolving Stream Loading View
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.showingStreams && root.isLoadingStreams
            color: "transparent"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: root.isLoadingStreams
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Resolving Real-Debrid high-speed stream..."
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }
            }
        }

        // Empty Streams Notice
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.showingStreams && !root.isLoadingStreams && (!root.streamResults || root.streamResults.length === 0)
            color: "transparent"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No active stream found for this item."
                    color: "#a0a0b0"
                    font.pixelSize: 14
                }

                StyledButton {
                    Layout.alignment: Qt.AlignHCenter
                    text: "← Back to Search"
                    primary: true
                    onClicked: (mouse) => {
                        root.showingStreams = false
                    }
                }
            }
        }

        // Alternative Streams List View (Fallback only if manual stream selection is needed)
        ListView {
            id: streamsListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.showingStreams && !root.isLoadingStreams && root.streamResults && root.streamResults.length > 0
            clip: true
            model: root.streamResults

            delegate: Rectangle {
                id: streamCard
                width: streamsListView.width
                height: 70
                color: streamMouseArea.containsMouse ? "#242436" : "#14141e"
                radius: 10
                border.color: streamMouseArea.containsMouse ? "#7B68EE" : "#20202e"
                border.width: 1

                MouseArea {
                    id: streamMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
                        playDirectStream(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: modelData.title || modelData.name || modelData.description || "Stream Source"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (modelData.url && modelData.url.indexOf("real-debrid") !== -1)
                                    ? "⚡ Real-Debrid Instant High-Speed Direct Stream"
                                    : (modelData.url ? "🔗 Direct Stream Link" : "⚡ Addon Stream")
                                color: (modelData.url && modelData.url.indexOf("real-debrid") !== -1) ? "#00E676" : "#4DD0E1"
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        StyledButton {
                            text: "▶ Play on Slot " + (root.targetSlot + 1)
                            success: true
                            onClicked: (mouse) => {
                                playDirectStream(modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    function openForSlot(slotIdx) {
        root.targetSlot = slotIdx
        root.showingStreams = false
        root.isLoadingStreams = false
        if (root.activeSource === "backend" && (!root.searchResults || root.searchResults.length === 0)) {
            loadBackendCatalog()
        }
        root.open()
    }

    function loadBackendCatalog() {
        root.searchResults = QuadController.fetchCatalog(QuadController.defaultAddonUrl, "movie", "torrent-search", "")
    }

    function executeSearch() {
        if (searchInput.text.trim().length === 0) return
        if (root.activeSource === "backend") {
            root.searchResults = QuadController.fetchCatalog(QuadController.defaultAddonUrl, "movie", "torrent-search", searchInput.text.trim())
        } else {
            root.searchResults = QuadController.searchContent(searchInput.text.trim(), typeCombo.currentText)
        }
    }

    function autoPlayItem(meta) {
        var addonUrl = (root.activeSource === "backend") ? QuadController.defaultAddonUrl : "https://torrentio.strem.fun"
        var itemType = meta.type || "movie"
        var id = meta.id

        // 1-Click Auto-Resolve: Fetch top stream and play immediately
        var streams = QuadController.resolveStreams(addonUrl, itemType, id)
        if (streams && streams.length > 0) {
            var topStream = streams[0]
            var streamUrl = topStream.url || ""
            if (!streamUrl && topStream.infoHash) {
                streamUrl = "http://127.0.0.1:11470/" + topStream.infoHash + "/" + (topStream.fileIdx || 0)
            }
            QuadController.loadStream(
                root.targetSlot,
                meta.name || meta.title || topStream.title || "Stream",
                meta.poster || "",
                streamUrl
            )
            root.close()
        } else {
            // If no stream resolved immediately, open streams view with error notice
            root.selectedMeta = meta
            root.showingStreams = true
            root.isLoadingStreams = false
            root.streamResults = []
        }
    }

    function playDirectStream(modelData) {
        var streamUrl = modelData.url || ""
        if (!streamUrl && modelData.infoHash) {
            streamUrl = "http://127.0.0.1:11470/" + modelData.infoHash + "/" + (modelData.fileIdx || 0)
        }
        
        var streamTitle = root.selectedMeta 
            ? (root.selectedMeta.name || root.selectedMeta.title || "Stream") 
            : (modelData.title || modelData.name || "Stream")
        var streamPoster = root.selectedMeta ? (root.selectedMeta.poster || "") : ""

        QuadController.loadStream(
            root.targetSlot,
            streamTitle,
            streamPoster,
            streamUrl
        )
        root.close()
    }
}
