import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control

    property bool primary: false
    property bool success: false
    property bool activePill: false
    property int customRadius: 8

    font.pixelSize: 12
    font.bold: true

    contentItem: Text {
        text: control.text
        font: control.font
        color: {
            if (!control.enabled) return "#606072";
            if (control.primary || control.activePill) return "#ffffff";
            if (control.success) return "#0d0d12";
            return control.hovered ? "#ffffff" : "#c4c4d8";
        }
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 72
        implicitHeight: 32
        radius: control.customRadius
        border.width: 1

        color: {
            if (!control.enabled) return "#121218";
            if (control.primary || control.activePill) {
                if (control.down) return "#5c4ec4";
                if (control.hovered) return "#8a77ff";
                return "#7B68EE";
            }
            if (control.success) {
                if (control.down) return "#00b359";
                if (control.hovered) return "#26ff93";
                return "#00E676";
            }
            if (control.down) return "#2c2c3d";
            if (control.hovered) return "#242434";
            return "#171722";
        }

        border.color: {
            if (control.primary || control.activePill) return control.hovered ? "#ab9eff" : "#8e7eff";
            if (control.success) return control.hovered ? "#66ffa6" : "#00E676";
            if (control.hovered) return "#424258";
            return "#282838";
        }

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    scale: control.down ? 0.96 : (control.hovered ? 1.02 : 1.0)
    Behavior on scale { NumberAnimation { duration: 90 } }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }
}
