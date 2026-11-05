// Cut-and-paste ransom lettering: each glyph on its own scissor-cut scrap
// (irregular quad, hard paper shadow), mixed stock, case and fonts, the odd
// strip of tape. Vector shapes so the edges stay clean when tilted.
import QtQuick
import QtQuick.Shapes

Row {
    id: root

    property string text
    property real size: 48
    property int seed: 17
    property bool autoGlitch: false
    property bool glitching: false
    property int tick: 0
    property color red: "#e60012"
    property color ink: "#0a0a0a"
    property color paper: "#f4f4f4"
    property color news: "#d8d2c2"

    readonly property var cutFonts: [
        ["Bebas Neue", Font.Normal, false],
        ["Antonio", Font.Bold, false],
        ["Noto Serif", Font.Black, true],
        ["DejaVu Serif", Font.Bold, false],
        ["Noto Sans", Font.Black, false],
        ["JetBrainsMono NF", Font.ExtraBold, false],
        ["DejaVu Sans Mono", Font.Bold, false],
        ["Noto Serif", Font.Normal, true],
        ["Liberation Serif", Font.Bold, true],
        ["Rubik", Font.Black, false],
        ["Carlito", Font.Bold, false],
        ["Liberation Mono", Font.Bold, false],
        ["Cantarell", Font.ExtraBold, false],
        ["Bitstream Vera Serif", Font.Bold, false]
    ]

    function rnd(s, i, k) {
        const x = Math.sin(s * 12.9898 + i * 78.233 + k * 37.719) * 43758.5453;
        return x - Math.floor(x);
    }

    function glitch() {
        burstTimer.left = 7;
        burstTimer.restart();
    }

    spacing: -size * 0.06

    Timer {
        id: burstTimer
        property int left: 0
        interval: 45
        repeat: true
        onTriggered: {
            root.tick++;
            root.glitching = --left > 0;
            if (left <= 0)
                stop();
        }
    }

    Timer {
        running: root.autoGlitch
        repeat: true
        interval: 5000 + Math.floor(root.rnd(root.seed, root.tick, 9) * 9000)
        onTriggered: root.glitch()
    }

    Repeater {
        model: root.text.length

        Item {
            id: g

            required property int index
            readonly property string raw: root.text.charAt(index)
            readonly property real n1: root.rnd(root.seed, index, 1)
            readonly property real n2: root.rnd(root.seed, index, 2)
            readonly property real n3: root.rnd(root.seed, index, 3)
            readonly property real n4: root.rnd(root.seed, index, 4)
            readonly property real n5: root.rnd(root.seed, index, 5)
            readonly property real n6: root.rnd(root.seed, index, 6)
            readonly property string ch: n2 < 0.5 ? raw.toUpperCase() : raw.toLowerCase()
            readonly property var face: root.cutFonts[Math.floor(n1 * root.cutFonts.length)]
            // 0 paper, 1 newsprint, 2 ink, 3 red
            readonly property int stock: n6 < 0.32 ? 0 : n6 < 0.6 ? 1 : n6 < 0.78 ? 2 : 3
            readonly property real fs: root.size * (0.74 + n4 * 0.62)
            readonly property real jitter: root.glitching ? (root.rnd(root.tick, index, 7) - 0.5) * root.size * 0.3 : 0

            width: raw === " " ? root.size * 0.45 : scrap.width * 0.94
            height: root.size * 1.7

            Item {
                id: scrap

                visible: g.raw !== " "
                x: g.jitter
                width: glyph.implicitWidth + g.fs * 0.32
                height: g.fs * 1.12
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: (g.n5 - 0.5) * root.size * 0.38
                rotation: (g.n3 - 0.5) * 40

                readonly property real j: g.fs * 0.09
                function cut(dx, dy) {
                    const w = width, h = height, j = scrap.j;
                    const r = k => root.rnd(root.seed, g.index, 20 + k);
                    return [Qt.point(dx + j * r(0), dy + j * r(1)), Qt.point(dx + w - j * r(2), dy + j * r(3)),
                            Qt.point(dx + w - j * r(4), dy + h - j * r(5)), Qt.point(dx + j * r(6), dy + h - j * r(7)),
                            Qt.point(dx + j * r(0), dy + j * r(1))];
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        fillColor: g.stock === 2 ? root.red : root.ink
                        strokeWidth: -1
                        PathPolyline { path: scrap.cut(g.fs * 0.07, g.fs * 0.07) }
                    }
                    ShapePath {
                        fillGradient: LinearGradient {
                            x1: scrap.width * g.n4; y1: 0
                            x2: scrap.width * (1 - g.n4); y2: scrap.height
                            GradientStop { position: 0; color: [root.paper, root.news, root.ink, root.red][g.stock] }
                            GradientStop { position: 0.55 + g.n5 * 0.2; color: Qt.darker([root.paper, root.news, root.ink, root.red][g.stock], 1.08) }
                            GradientStop { position: 1; color: Qt.darker([root.paper, root.news, root.ink, root.red][g.stock], 1.22) }
                        }
                        strokeColor: g.stock === 2 ? root.paper : "transparent"
                        strokeWidth: g.stock === 2 ? Math.max(2, g.fs * 0.045) : -1
                        PathPolyline { path: scrap.cut(0, 0) }
                    }
                    // crumple creases
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: g.stock === 2 ? Qt.alpha(root.paper, 0.14) : Qt.alpha(root.ink, 0.2)
                        strokeWidth: 1
                        PathPolyline {
                            path: [Qt.point(scrap.width * g.n3, 2), Qt.point(scrap.width * (0.3 + g.n1 * 0.4), scrap.height * 0.5), Qt.point(scrap.width * g.n5, scrap.height - 2)]
                        }
                    }
                    ShapePath {
                        fillColor: "transparent"
                        strokeColor: g.stock === 2 ? Qt.alpha(root.paper, 0.1) : Qt.alpha(root.ink, 0.14)
                        strokeWidth: 1
                        PathPolyline {
                            path: [Qt.point(2, scrap.height * g.n2), Qt.point(scrap.width * 0.55, scrap.height * (0.3 + g.n6 * 0.4)), Qt.point(scrap.width - 2, scrap.height * g.n4)]
                        }
                    }
                }

                Text {
                    visible: root.glitching
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -g.fs * 0.08
                    text: g.ch
                    font: glyph.font
                    color: Qt.alpha(root.red, 0.85)
                }
                Text {
                    visible: root.glitching
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: g.fs * 0.08
                    text: g.ch
                    font: glyph.font
                    color: Qt.alpha("#00e5ff", 0.7)
                }
                Text {
                    id: glyph
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -g.fs * 0.02
                    text: g.ch
                    font.family: g.face[0]
                    font.weight: g.face[1]
                    font.italic: g.face[2]
                    font.pixelSize: g.fs
                    color: g.stock <= 1 ? root.ink : root.paper
                }

                // tape
                Rectangle {
                    visible: g.n1 > 0.62
                    x: g.n2 < 0.5 ? -width * 0.25 : parent.width - width * 0.75
                    y: -height * 0.35
                    width: g.fs * 0.55
                    height: g.fs * 0.17
                    rotation: g.n2 < 0.5 ? -38 : 38
                    antialiasing: true
                    color: Qt.alpha(root.paper, 0.55)
                }
            }
        }
    }
}
