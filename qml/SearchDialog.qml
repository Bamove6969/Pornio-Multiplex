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
        color: "#14141c"
        radius: 12
        border.color: "#282836"
        border.width: 1
    }

    header: Rectangle {
        height: 54
        color: "#1c1c28"
        radius: 12

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: root.showingStreams 
                    ? ("Available Streams: " + (root.selectedMeta ? (root.selectedMeta.name || root.selectedMeta.title || "") : "")) 
                    : ("Select Content for Slot " + (targetSlot + 1))
                color: "white"
                font.bold: true
                font.pixelSize: 15
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Button {
                text: root.showingStreams ? "← Back to Catalog" : "✕ Close"
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
        spacing: 10

        // Source Switcher Tabs
        RowLayout {
            Layout.fillWidth: true
            visible: !root.showingStreams
            spacing: 8

            Button {
                text: "⚡ Your Backend (RD + Jackett)"
                highlighted: root.activeSource === "backend"
                onClicked: (mouse) => {
                    root.activeSource = "backend"
                    loadBackendCatalog()
                }
            }

            Button {
                text: "🎬 Cinemeta (IMDb/TMDB)"
                highlighted: root.activeSource === "cinemeta"
                onClicked: (mouse) => {
                    root.activeSource = "cinemeta"
                    root.searchResults = []
                }
            }

            Button {
                text: "🔗 Direct URL / Presets"
                highlighted: root.activeSource === "direct"
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
                background: Rectangle {
                    color: "#0e0e13"
                    radius: 8
                    border.color: searchInput.activeFocus ? "#7B68EE" : "#2a2a36"
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
                    color: "#0e0e13"
                    radius: 8
                    border.color: "#2a2a36"
                }
            }

            Button {
                text: "Search"
                highlighted: true
                onClicked: (mouse) => { executeSearch() }
            }

            Button {
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
                    background: Rectangle {
                        color: "#0e0e13"
                        radius: 8
                        border.color: "#2a2a36"
                    }
                }

                Button {
                    text: "Load URL"
                    highlighted: true
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
                color: "#888"
                font.pixelSize: 12
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    text: "Big Buck Bunny"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Big Buck Bunny", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
                        root.close()
                    }
                }
                Button {
                    text: "Elephant's Dream"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Elephant's Dream", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")
                        root.close()
                    }
                }
                Button {
                    text: "Tears of Steel"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Tears of Steel", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4")
                        root.close()
                    }
                }
                Button {
                    text: "Sintel"
                    onClicked: (mouse) => {
                        QuadController.loadStream(root.targetSlot, "Sintel", "", "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4")
                        root.close()
                    }
                }
            }
        }

        // Catalog Results List View
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
                height: 72
                color: itemMouse.containsMouse ? "#242432" : "#171720"
                radius: 8

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
                        root.selectedMeta = modelData
                        fetchStreams(modelData.type || "movie", modelData.id)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 56
                            color: "#20202c"
                            radius: 4

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
                            spacing: 2

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

                        Button {
                            text: "Streams →"
                            highlighted: true
                            onClicked: (mouse) => {
                                root.selectedMeta = modelData
                                fetchStreams(modelData.type || "movie", modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // Streams Loading / Resolving View
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
                    text: "Resolving Real-Debrid streams from your backend..."
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
                    text: "No direct streams found for this item."
                    color: "#a0a0b0"
                    font.pixelSize: 14
                }

                Button {
                    Layout.alignment: Qt.AlignHCenter
                    text: "← Back to Catalog"
                    highlighted: true
                    onClicked: (mouse) => {
                        root.showingStreams = false
                    }
                }
            }
        }

        // Stream Selection List View
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
                height: 68
                color: streamMouseArea.containsMouse ? "#28283c" : "#171722"
                radius: 8
                border.color: streamMouseArea.containsMouse ? "#7B68EE" : "#242434"
                border.width: 1

                MouseArea {
                    id: streamMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: (mouse) => {
                        playStream(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
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

                        Button {
                            text: "▶ Play on Slot " + (root.targetSlot + 1)
                            highlighted: true
                            onClicked: (mouse) => {
                                playStream(modelData)
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

    function fetchStreams(itemType, id) {
        var addonUrl = (root.activeSource === "backend") ? QuadController.defaultAddonUrl : "https://torrentio.strem.fun"
        root.showingStreams = true
        root.isLoadingStreams = true
        root.streamResults = []

        // Resolve streams via background worker / Qt
        var results = QuadController.resolveStreams(addonUrl, itemType, id)
        root.streamResults = results
        root.isLoadingStreams = false
    }

    function playStream(modelData) {
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
