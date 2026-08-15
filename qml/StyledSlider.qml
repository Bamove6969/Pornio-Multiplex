import QtQuick 2.15
import QtQuick.Controls 2.15

Slider {
    id: control

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: 2
        color: "#28283a"

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: "#7B68EE"
            radius: 2
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        implicitWidth: control.hovered || control.pressed ? 14 : 10
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        color: "#ffffff"
        border.color: "#7B68EE"
        border.width: 2

        Behavior on implicitWidth { NumberAnimation { duration: 100 } }
        Behavior on implicitHeight { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }
}
