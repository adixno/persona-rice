// Slanted card drawn as a vector path (stays crisp; rotated Rectangles alias).
// Fill, outline and a hard offset shadow. Children land in the card's area.
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property color fill: "#e60012"
    property color outline: "#f4f4f4"
    property color shadow: "#000000"
    property real outlineWidth: 3
    property real skew: 10
    property real shadowOffset: 5
    default property alias content: holder.data

    function quad(dx, dy) {
        const s = skew, w = width - shadowOffset, h = height - shadowOffset;
        return [Qt.point(s + dx, dy), Qt.point(w + dx, dy), Qt.point(w - s + dx, h + dy), Qt.point(dx, h + dy), Qt.point(s + dx, dy)];
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.shadow
            strokeWidth: -1
            PathPolyline { path: root.quad(root.shadowOffset, root.shadowOffset) }
        }
        ShapePath {
            fillColor: root.fill
            strokeColor: root.outline
            strokeWidth: root.outlineWidth
            joinStyle: ShapePath.MiterJoin
            PathPolyline { path: root.quad(0, 0) }
        }
    }

    Item { id: holder; anchors.fill: parent }
}
