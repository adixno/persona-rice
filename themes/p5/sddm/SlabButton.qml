// Clickable slab with a label; lifts and flips colour on hover.
import QtQuick

Item {
    id: root

    property string label
    property color fill: "#f4f4f4"
    property color hoverFill: "#e60012"
    property color textColor: "#0a0a0a"
    property color hoverText: "#f4f4f4"
    property color outline: "#0a0a0a"
    property color shadow: "#000000"
    property string fontFamily: "Bebas Neue"
    property real fontSize: 36
    property real skew: 8
    property real shadowOffset: 5
    readonly property bool hovered: ma.containsMouse && root.enabled
    signal clicked

    Slab {
        x: root.hovered ? -2 : 0
        y: root.hovered ? -2 : 0
        width: root.width
        height: root.height
        fill: root.hovered ? root.hoverFill : root.fill
        outline: root.outline
        shadow: root.shadow
        skew: root.skew
        shadowOffset: root.hovered ? root.shadowOffset + 2 : root.shadowOffset
        Behavior on x { NumberAnimation { duration: 70 } }
        Behavior on y { NumberAnimation { duration: 70 } }
    }

    Text {
        x: (root.width - root.shadowOffset - width) / 2 + (root.hovered ? -2 : 0)
        y: (root.height - root.shadowOffset - height) / 2 + (root.hovered ? -2 : 0)
        text: root.label
        font.family: root.fontFamily
        font.pixelSize: root.fontSize
        font.letterSpacing: root.fontSize * 0.05
        color: root.hovered ? root.hoverText : root.textColor
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
