import QtQuick 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    property bool isMaximumMode: false

    signal requestOpenSearch(int slot)

    GridLayout {
        anchors.fill: parent
        columns: 2
        rows: 2
        columnSpacing: 0
        rowSpacing: 0

        Repeater {
            model: 4
            delegate: PlayerSlot {
                Layout.fillWidth: true
                Layout.fillHeight: true
                slotIndex: index
                isMaximumMode: root.isMaximumMode
                slotData: (QuadController.slotList && QuadController.slotList.length > index) ? QuadController.slotList[index] : null
                visible: (QuadController.soloSlot === -1) || (QuadController.soloSlot === index)
                onRequestOpenSearch: (slot) => {
                    root.requestOpenSearch(slot)
                }
            }
        }
    }
}
