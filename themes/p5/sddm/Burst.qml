// Jagged starburst sticker: rim, edge, coloured core.
import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property color fill: "#e60012"
    property color edge: "#f4f4f4"
    property color rim: "#0a0a0a"
    property int spikes: 11
    property int seed: 3

    function rnd(s, i, k) {
        const x = Math.sin(s * 12.9898 + i * 78.233 + k * 37.719) * 43758.5453;
        return x - Math.floor(x);
    }

    function points(grow) {
        const pts = [];
        const n = spikes * 2;
        for (let i = 0; i <= n; i++) {
            const a = (i % n) / n * Math.PI * 2 - Math.PI / 2;
            const r = (i % 2 === 0 ? 1 : 0.68 + 0.14 * rnd(seed, i, 3)) * (0.86 + 0.14 * rnd(seed, i, 4)) + grow;
            pts.push(Qt.point(width / 2 + Math.cos(a) * width / 2 * r, height / 2 + Math.sin(a) * height / 2 * r));
        }
        return pts;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.rim
        strokeWidth: -1
        PathPolyline { path: root.points(0.12) }
    }
    ShapePath {
        fillColor: root.edge
        strokeWidth: -1
        PathPolyline { path: root.points(0.06) }
    }
    ShapePath {
        fillColor: root.fill
        strokeWidth: -1
        PathPolyline { path: root.points(-0.04) }
    }
}
