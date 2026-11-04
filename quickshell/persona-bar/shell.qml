// Bottom taskbar: punk / ransom-note style, matched to the Caelestia "persona" scheme.
// Colours are read live from Caelestia's scheme.json; shell actions go through the caelestia CLI.
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

ShellRoot {
    id: root

    // ---- theme ----
    property var colours: ({})
    readonly property color red: "#" + (colours.primary ?? "e60012")
    readonly property color redDeep: "#" + (colours.primaryContainer ?? "5c0007")
    readonly property color ink: "#" + (colours.background ?? "0a0a0a")
    readonly property color paper: "#" + (colours.onSurface ?? "f4f4f4")
    readonly property color dim: "#" + (colours.onSurfaceVariant ?? "c8c8c8")
    readonly property color cyan: "#00e5ff" // glitch split only
    readonly property string icons: "Material Symbols Sharp"

    readonly property int barHeight: 50 // reserved space; keep in sync with sync-caelestia.sh
    readonly property int tear: 10 // extra height for the torn bottom edge

    // fonts mixed by the ransom-note lettering: [family, weight, italic]
    readonly property var cutFonts: [
        ["Bebas Neue", Font.Normal, false],
        ["Antonio", Font.Bold, false],
        ["Noto Sans", Font.Black, true],
        ["DejaVu Serif", Font.Bold, false],
        ["Noto Serif", Font.Black, true],
        ["JetBrainsMono NF", Font.ExtraBold, false]
    ]

    FileView {
        path: Quickshell.env("HOME") + "/.local/state/caelestia/scheme.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.colours = JSON.parse(text()).colours;
            } catch (e) {
                console.warn("persona-bar: bad scheme.json", e);
            }
        }
    }

    // deterministic noise in [0, 1)
    function rnd(seed: real, i: real, k: real): real {
        const x = Math.sin(seed * 12.9898 + i * 78.233 + k * 37.719) * 43758.5453;
        return x - Math.floor(x);
    }

    function hash(s: string): int {
        let h = 7;
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) % 100003;
        return h;
    }

    // jagged starburst outline fitted to w x h
    function burst(w: real, h: real, spikes: int, seed: real, grow: real): var {
        const pts = [];
        const n = spikes * 2;
        for (let i = 0; i <= n; i++) {
            const a = (i % n) / n * Math.PI * 2 - Math.PI / 2;
            const outer = i % 2 === 0;
            const r = (outer ? 1 : 0.68 + 0.14 * rnd(seed, i, 3)) * (0.86 + 0.14 * rnd(seed, i, 4)) + grow;
            pts.push(Qt.point(w / 2 + Math.cos(a) * w / 2 * r, h / 2 + Math.sin(a) * h / 2 * r));
        }
        return pts;
    }

    function caelestia(args: list<string>): void {
        Quickshell.execDetached(["caelestia", ...args]);
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---- reusable pieces ----

    // Ransom-note lettering: every glyph is its own cut-out tile
    component Ransom: Row {
        id: r
        property string text
        property real size: 22
        property int seed: root.hash(text)
        property int forceStyle: -1 // 0 white tile, 1 black tile, 2 red tile, 3 bare
        property bool autoGlitch: false
        property bool glitching: false
        property int tick: 0

        function glitch(): void {
            burstTimer.left = 7;
            burstTimer.restart();
        }

        spacing: -2
        onTextChanged: glitch()

        Timer {
            id: burstTimer
            property int left: 0
            interval: 45
            repeat: true
            onTriggered: {
                r.tick++;
                r.glitching = --left > 0;
                if (left <= 0)
                    stop();
            }
        }
        Timer {
            running: r.autoGlitch
            repeat: true
            interval: 4000 + Math.floor(root.rnd(r.seed, r.tick, 9) * 9000)
            onTriggered: r.glitch()
        }

        Repeater {
            model: r.text.length

            Item {
                id: g
                required property int index
                readonly property string ch: r.text.charAt(index)
                readonly property real n1: root.rnd(r.seed, index, 1)
                readonly property real n2: root.rnd(r.seed, index, 2)
                readonly property real n3: root.rnd(r.seed, index, 5)
                readonly property var face: root.cutFonts[Math.floor(n1 * root.cutFonts.length)]
                readonly property int style: r.forceStyle >= 0 ? r.forceStyle : n2 < 0.36 ? 0 : n2 < 0.66 ? 1 : n2 < 0.86 ? 2 : 3
                readonly property real jitter: r.glitching ? (root.rnd(r.tick, index, 7) - 0.5) * 6 : 0

                width: ch === " " ? r.size * 0.3 : tile.width
                height: r.size * 1.3

                Rectangle {
                    id: tile
                    visible: g.ch !== " "
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: (g.n3 - 0.5) * r.size * 0.18
                    x: g.jitter
                    width: glyph.implicitWidth + r.size * 0.22
                    height: glyph.implicitHeight * 0.92
                    rotation: (g.n3 - 0.5) * 18
                    antialiasing: true
                    color: g.style === 0 ? root.paper : g.style === 1 ? root.ink : g.style === 2 ? root.red : "transparent"
                    border.color: g.style === 1 ? root.paper : root.ink
                    border.width: g.style === 3 ? 0 : 2

                    // red/cyan split while glitching
                    Text {
                        visible: r.glitching
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -3
                        text: g.ch
                        font: glyph.font
                        color: Qt.alpha(root.red, 0.85)
                    }
                    Text {
                        visible: r.glitching
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: 3
                        text: g.ch
                        font: glyph.font
                        color: Qt.alpha(root.cyan, 0.75)
                    }
                    Text {
                        id: glyph
                        anchors.centerIn: parent
                        text: g.ch
                        font.family: g.face[0]
                        font.weight: g.face[1]
                        font.italic: g.face[2]
                        font.pixelSize: r.size * (0.86 + g.n1 * 0.3)
                        color: g.style === 0 ? root.ink : root.paper
                        style: g.style === 3 ? Text.Outline : Text.Normal
                        styleColor: root.ink
                    }
                }
            }
        }
    }

    // Starburst sticker: white outline, coloured core
    component Burst: Shape {
        id: b
        property color fill: root.red
        property color edge: root.paper
        property int spikes: 11
        property int seed: 3
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.ink
            strokeWidth: -1
            PathPolyline { path: root.burst(b.width, b.height, b.spikes, b.seed, 0.12) }
        }
        ShapePath {
            fillColor: b.edge
            strokeWidth: -1
            PathPolyline { path: root.burst(b.width, b.height, b.spikes, b.seed, 0.06) }
        }
        ShapePath {
            fillColor: b.fill
            strokeWidth: -1
            PathPolyline { path: root.burst(b.width, b.height, b.spikes, b.seed, -0.04) }
        }
    }

    component Icon: Text {
        font.family: root.icons
        font.pixelSize: 20
        color: root.paper
        verticalAlignment: Text.AlignVCenter
    }

    // Tilted sticker chip: black card, white border, red offset shadow
    component Chip: Item {
        id: chip
        property string icon
        property string label
        property bool hot: false
        property real tilt: -3
        signal clicked(var mouse)
        signal scrolled(int delta)

        implicitWidth: row.implicitWidth + 22
        implicitHeight: 34
        rotation: tilt
        scale: area.containsMouse ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

        Rectangle {
            x: 4; y: 4
            width: parent.width; height: parent.height
            color: root.red
            antialiasing: true
        }
        Rectangle {
            anchors.fill: parent
            color: chip.hot || area.containsMouse ? root.red : root.ink
            border.color: root.paper
            border.width: 3
            antialiasing: true
        }

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 4

            Icon {
                visible: chip.icon !== ""
                text: chip.icon
                color: chip.hot || area.containsMouse ? root.paper : root.red
            }
            Ransom {
                id: lbl
                visible: chip.label !== ""
                text: chip.label
                size: 17
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            onEntered: lbl.glitch()
            onClicked: mouse => chip.clicked(mouse)
            onWheel: wheel => chip.scrolled(wheel.angleDelta.y)
        }
    }

    // ---- the bar ----
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData

            anchors { left: true; right: true; top: true }
            implicitHeight: root.barHeight + root.tear
            exclusiveZone: root.barHeight
            color: "transparent"

            readonly property var monitor: Hyprland.monitorFor(modelData)

            // torn-paper background: red under-layer peeking out below the black (drawn top-up, then flipped)
            Shape {
                id: torn
                anchors.fill: parent
                transform: Scale { yScale: -1; origin.y: torn.height / 2 }
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    fillColor: root.red
                    strokeWidth: -1
                    PathPolyline { path: torn.tornEdge(bar.width, bar.height, 0, 41) }
                }
                ShapePath {
                    fillColor: root.paper
                    strokeWidth: -1
                    PathPolyline { path: torn.tornEdge(bar.width, bar.height, 4, 17) }
                }
                ShapePath {
                    fillColor: root.ink
                    strokeWidth: -1
                    PathPolyline { path: torn.tornEdge(bar.width, bar.height, 7, 5) }
                }

                function tornEdge(w: real, h: real, base: real, seed: real): var {
                    const pts = [Qt.point(0, h)];
                    let x = 0, i = 0;
                    while (x < w) {
                        pts.push(Qt.point(x, base + root.rnd(seed, i, 1) * (root.tear - 2)));
                        x += 14 + root.rnd(seed, i, 2) * 34;
                        i++;
                    }
                    pts.push(Qt.point(w, base + root.tear / 2), Qt.point(w, h), Qt.point(0, h));
                    return pts;
                }
            }

            // halftone dots fading in from both ends
            Canvas {
                anchors { fill: parent; bottomMargin: root.tear + 4 }
                opacity: 0.35
                onWidthChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = root.redDeep;
                    const step = 9;
                    for (let y = 2; y < height; y += step)
                        for (let x = (y / step % 2) * step / 2; x < width; x += step) {
                            const t = Math.max(0, 1 - Math.min(x, width - x) / (width * 0.22));
                            if (t <= 0)
                                continue;
                            ctx.beginPath();
                            ctx.arc(x, y, 3.6 * t, 0, Math.PI * 2);
                            ctx.fill();
                        }
                }
            }

            // red slash behind the clock
            Shape {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4
                width: 280; height: root.barHeight - 10
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: root.red
                    strokeWidth: -1
                    PathPolyline { path: [Qt.point(26, 0), Qt.point(280, 6), Qt.point(256, 40), Qt.point(0, 34), Qt.point(26, 0)] }
                }
            }

            Item {
                anchors { fill: parent; bottomMargin: root.tear }

                // left: launcher burst, workspaces, window title
                RowLayout {
                    id: leftRow
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 4 }
                    spacing: 10

                    Item {
                        implicitWidth: 96
                        implicitHeight: root.barHeight + 4
                        scale: launchArea.containsMouse ? 1.1 : 1
                        rotation: launchArea.containsMouse ? -6 : -3
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                        Burst {
                            anchors.fill: parent
                            spikes: 13
                            seed: 21
                        }
                        Ransom {
                            id: menuText
                            anchors.centerIn: parent
                            text: "MENU"
                            size: 17
                            seed: 8
                        }
                        MouseArea {
                            id: launchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: menuText.glitch()
                            onClicked: root.caelestia(["shell", "drawers", "toggle", "launcher"])
                        }
                    }

                    Row {
                        spacing: 2

                        Repeater {
                            model: 5

                            Item {
                                id: ws
                                required property int index
                                readonly property int wsId: index + 1
                                readonly property bool active: bar.monitor?.activeWorkspace?.id === wsId
                                readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId && w.toplevels.values.length > 0)

                                width: active ? 52 : 32
                                height: root.barHeight - 4
                                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }

                                Burst {
                                    anchors.centerIn: parent
                                    width: 52; height: 48
                                    visible: ws.active
                                    seed: 40 + ws.wsId
                                    spikes: 9
                                    rotation: ws.wsId * 23
                                }
                                Ransom {
                                    id: wsNum
                                    anchors.centerIn: parent
                                    text: String(ws.wsId)
                                    seed: ws.wsId * 13
                                    size: ws.active ? 26 : 19
                                    forceStyle: ws.active ? 1 : ws.occupied ? 0 : 3
                                    opacity: ws.active || ws.occupied || wsArea.containsMouse ? 1 : 0.45
                                }
                                onActiveChanged: if (active) wsNum.glitch()

                                MouseArea {
                                    id: wsArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: wsNum.glitch()
                                    onClicked: Hyprland.dispatch(`workspace ${ws.wsId}`)
                                }
                            }
                        }
                    }

                    // window title on a torn white label
                    Item {
                        id: titleBox
                        // never reach the clock: cap at the space left before it
                        readonly property real room: clockBox.x - leftRow.x - x - 30
                        visible: titleText.text !== "" && room > 60
                        Layout.leftMargin: 6
                        implicitWidth: Math.max(0, Math.min(titleText.implicitWidth + 22, room))
                        implicitHeight: 26
                        rotation: -2

                        Rectangle {
                            x: 3; y: 3
                            width: parent.width; height: parent.height
                            color: root.red
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: root.paper
                            antialiasing: true
                        }
                        Text {
                            id: titleText
                            anchors { fill: parent; leftMargin: 11; rightMargin: 11 }
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            text: (Hyprland.activeToplevel?.title ?? "").toUpperCase()
                            font.family: "Antonio"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: root.ink
                        }
                    }
                }

                // centre: ransom clock + weekday, opens the dashboard
                Item {
                    id: clockBox
                    anchors.centerIn: parent
                    implicitWidth: clockRow.implicitWidth
                    implicitHeight: root.barHeight
                    scale: clockArea.containsMouse ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                    RowLayout {
                        id: clockRow
                        anchors.centerIn: parent
                        spacing: 10

                        Ransom {
                            id: clockText
                            text: Qt.formatDateTime(clock.date, "hh:mm")
                            size: 30
                            autoGlitch: true
                        }
                        ColumnLayout {
                            spacing: -6
                            Ransom {
                                text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
                                size: 18
                            }
                            Rectangle {
                                Layout.alignment: Qt.AlignRight
                                implicitWidth: dateText.implicitWidth + 10
                                implicitHeight: dateText.implicitHeight - 4
                                color: root.ink
                                border.color: root.paper
                                border.width: 2
                                rotation: -5
                                antialiasing: true
                                Text {
                                    id: dateText
                                    anchors.centerIn: parent
                                    text: Qt.formatDateTime(clock.date, "dd/MM")
                                    font.family: "Bebas Neue"
                                    font.pixelSize: 18
                                    font.italic: true
                                    color: root.paper
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: clockArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clockText.glitch()
                        onClicked: root.caelestia(["shell", "drawers", "toggle", "dashboard"])
                    }
                }

                // right: tray, volume, battery, notifications, power
                RowLayout {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 }
                    spacing: 10

                    Repeater {
                        model: SystemTray.items

                        Item {
                            id: trayItem
                            required property SystemTrayItem modelData
                            implicitWidth: 26
                            implicitHeight: 26

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 20
                                source: trayItem.modelData.icon
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    const item = trayItem.modelData;
                                    if (mouse.button === Qt.RightButton || item.onlyMenu) {
                                        if (item.hasMenu) {
                                            const p = trayItem.mapToItem(null, 0, 0);
                                            item.display(bar, p.x, p.y - 8);
                                        }
                                    } else {
                                        item.activate();
                                    }
                                }
                            }
                        }
                    }

                    Chip {
                        readonly property var audio: Pipewire.defaultAudioSink?.audio
                        readonly property int pct: Math.round((audio?.volume ?? 0) * 100)
                        tilt: -3
                        icon: !audio || audio.muted ? "volume_off" : pct > 50 ? "volume_up" : pct > 0 ? "volume_down" : "volume_mute"
                        label: !audio ? "--" : audio.muted ? "MUTE" : `${pct}%`
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton)
                                Quickshell.execDetached(["pavucontrol"]);
                            else if (audio)
                                audio.muted = !audio.muted;
                        }
                        onScrolled: delta => {
                            if (audio)
                                audio.volume = Math.max(0, Math.min(1, audio.volume + (delta > 0 ? 0.05 : -0.05)));
                        }
                    }

                    Chip {
                        readonly property var dev: UPower.displayDevice
                        readonly property int pct: Math.round((dev?.percentage ?? 0) * (dev?.percentage > 1 ? 1 : 100))
                        readonly property bool charging: dev?.state === UPowerDeviceState.Charging || dev?.state === UPowerDeviceState.FullyCharged
                        visible: dev?.isLaptopBattery ?? false
                        tilt: 2
                        hot: pct <= 15 && !charging
                        icon: charging ? "bolt" : pct > 15 ? "battery_full" : "battery_alert"
                        label: hot ? `LOW!! ${pct}%` : `${pct}%`
                    }

                    Chip {
                        tilt: -2
                        icon: "notifications"
                        onClicked: root.caelestia(["shell", "drawers", "toggle", "sidebar"])
                    }

                    Item {
                        implicitWidth: 58
                        implicitHeight: root.barHeight + 2
                        scale: powerArea.containsMouse ? 1.12 : 1
                        rotation: powerArea.containsMouse ? 12 : 0
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                        Burst {
                            anchors.fill: parent
                            spikes: 10
                            seed: 77
                            fill: powerArea.containsMouse ? root.paper : root.red
                        }
                        Icon {
                            anchors.centerIn: parent
                            text: "power_settings_new"
                            font.pixelSize: 24
                            color: powerArea.containsMouse ? root.red : root.paper
                        }
                        MouseArea {
                            id: powerArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.caelestia(["shell", "drawers", "toggle", "session"])
                        }
                    }
                }
            }
        }
    }
}
