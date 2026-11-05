// Persona SDDM theme: ransom-note title, slanted slabs, starburst sticker.
// Original design; palette comes from theme.conf.
import QtQuick
import QtQuick.Shapes

Rectangle {
    id: root

    width: 1280
    height: 720
    color: ink

    readonly property color red: config.red || "#e60012"
    readonly property color ink: config.ink || "#0a0a0a"
    readonly property color paper: config.paper || "#f4f4f4"
    readonly property real u: height / 720 // layout unit, 1 at 720p

    property int userIdx: 0
    property int sessIdx: 0
    property string userName: ""
    property string sessName: ""
    property bool busy: false
    property bool failed: false
    property date now: new Date()

    function refresh() {
        const ui = userRep.itemAt(userIdx);
        const si = sessRep.itemAt(sessIdx);
        userName = ui ? ui.uname : "";
        sessName = si ? si.sname : "";
    }

    function nextUser() {
        if (userRep.count > 1) {
            userIdx = (userIdx + 1) % userRep.count;
            refresh();
            pw.forceActiveFocus();
        }
    }

    function nextSession() {
        if (sessRep.count > 1) {
            sessIdx = (sessIdx + 1) % sessRep.count;
            refresh();
        }
    }

    function login() {
        if (busy || userName === "")
            return;
        busy = true;
        failed = false;
        sddm.login(userName, pw.text, sessIdx);
    }

    Component.onCompleted: {
        sessIdx = Math.max(0, sessionModel.lastIndex);
        refresh();
        pw.forceActiveFocus();
    }

    // Hidden models → plain values
    Repeater {
        id: userRep
        model: userModel
        delegate: Item {
            required property int index
            required property string name
            readonly property string uname: name
            Component.onCompleted: {
                if (uname === userModel.lastUser)
                    root.userIdx = index;
                root.refresh();
            }
        }
    }
    Repeater {
        id: sessRep
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            readonly property string sname: name
            Component.onCompleted: root.refresh()
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            pw.text = "";
            shake.restart();
            title.glitch();
            pw.forceActiveFocus();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    // ── backdrop ───────────────────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#f20a0a0a" }
            GradientStop { position: 0.55; color: "#b00a0a0a" }
            GradientStop { position: 1.0; color: "#660a0a0a" }
        }
    }

    // red slash wedge with a paper edge, rising from the bottom-left corner
    function wedge(d) {
        const w = width, h = height;
        return [Qt.point(0.20 * w + d, 1.02 * h), Qt.point(0.60 * w + d, -0.02 * h), Qt.point(0.75 * w + d, -0.02 * h), Qt.point(0.35 * w + d, 1.02 * h), Qt.point(0.20 * w + d, 1.02 * h)];
    }
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.paper
            strokeWidth: -1
            PathPolyline { path: root.wedge(14 * root.u) }
        }
        ShapePath {
            fillColor: root.ink
            strokeWidth: -1
            PathPolyline { path: root.wedge(6 * root.u) }
        }
        ShapePath {
            fillColor: root.red
            strokeWidth: -1
            PathPolyline { path: root.wedge(0) }
        }
    }

    // ── title ──────────────────────────────────────────────────────────────
    RansomCut {
        id: title
        x: (root.width - width) / 2
        y: 120 * root.u
        text: "log in"
        size: 54 * root.u
        autoGlitch: true
        red: root.red
        ink: root.ink
        paper: root.paper
    }

    // marker scrawl under the title
    Shape {
        x: title.x - 6 * root.u
        y: title.y + title.height - 10 * root.u
        width: title.width + 30 * root.u
        height: 24 * root.u
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.red
            strokeWidth: 4 * root.u
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            startX: 0; startY: 14 * root.u
            PathCubic { x: 120 * root.u; y: 8 * root.u; control1X: 40 * root.u; control1Y: 4 * root.u; control2X: 80 * root.u; control2Y: 16 * root.u }
            PathCubic { x: 250 * root.u; y: 10 * root.u; control1X: 170 * root.u; control1Y: 0; control2X: 210 * root.u; control2Y: 18 * root.u }
            PathCubic { x: 70 * root.u; y: 20 * root.u; control1X: 190 * root.u; control1Y: 16 * root.u; control2X: 120 * root.u; control2Y: 24 * root.u }
        }
    }

    // scrawled circle-A: black marker with a white halo so it reads on red and on dark
    Item {
        id: anarchy
        x: title.x + title.width + 14 * root.u
        y: title.y + 6 * root.u
        width: 58 * root.u
        height: 58 * root.u
        rotation: -10

        component Mark: Shape {
            id: mk
            property color c
            property real w
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: "transparent"
                strokeColor: mk.c
                strokeWidth: mk.w
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                PathAngleArc { centerX: 29 * root.u; centerY: 30 * root.u; radiusX: 25 * root.u; radiusY: 23 * root.u; startAngle: -60; sweepAngle: 335 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: mk.c
                strokeWidth: mk.w * 1.1
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                startX: 6 * root.u; startY: 58 * root.u
                PathLine { x: 30 * root.u; y: -2 * root.u }
                PathLine { x: 53 * root.u; y: 56 * root.u }
                PathMove { x: 10 * root.u; y: 36 * root.u }
                PathLine { x: 52 * root.u; y: 32 * root.u }
            }
        }
        Mark { c: root.paper; w: 9 * root.u }
        Mark { c: root.ink; w: 4.5 * root.u }
    }

    // ── form ───────────────────────────────────────────────────────────────
    Item {
        id: form
        x: (root.width - width * scale) / 2 + shakeX
        y: 262 * root.u
        width: 470 * root.u
        scale: 0.8
        transformOrigin: Item.TopLeft
        height: 330 * root.u

        property real shakeX: 0

        SequentialAnimation {
            id: shake
            NumberAnimation { target: form; property: "shakeX"; to: -18 * root.u; duration: 50 }
            NumberAnimation { target: form; property: "shakeX"; to: 16 * root.u; duration: 70 }
            NumberAnimation { target: form; property: "shakeX"; to: -10 * root.u; duration: 60 }
            NumberAnimation { target: form; property: "shakeX"; to: 6 * root.u; duration: 50 }
            NumberAnimation { target: form; property: "shakeX"; to: 0; duration: 50 }
        }

        // user
        SlabButton {
            width: parent.width
            height: 70 * root.u
            label: ""
            fill: root.paper
            hoverFill: root.paper
            outline: root.ink
            shadow: root.red
            skew: 12 * root.u
            shadowOffset: 6 * root.u
            onClicked: root.nextUser()

            Text {
                x: 34 * root.u
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3 * root.u
                text: "USER"
                font.family: "Antonio"
                font.weight: Font.Bold
                font.pixelSize: 18 * root.u
                font.letterSpacing: 2 * root.u
                color: root.red
            }
            Text {
                x: 100 * root.u
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3 * root.u
                text: root.userName.toUpperCase()
                font.family: "Bebas Neue"
                font.pixelSize: 46 * root.u
                font.letterSpacing: 2 * root.u
                color: root.ink
            }
            Text {
                visible: userRep.count > 1
                anchors.right: parent.right
                anchors.rightMargin: 34 * root.u
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3 * root.u
                text: "▸▸"
                font.pixelSize: 22 * root.u
                color: root.red
            }
        }

        // password
        Slab {
            id: pwSlab
            y: 92 * root.u
            width: parent.width
            height: 76 * root.u
            fill: root.ink
            outline: pw.activeFocus ? root.red : root.paper
            shadow: root.red
            skew: 12 * root.u
            shadowOffset: 6 * root.u
            outlineWidth: 3 * root.u

            Text {
                x: 36 * root.u
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3 * root.u
                visible: pw.text.length === 0
                text: root.busy ? "..." : "PASSWORD"
                font.family: "Antonio"
                font.weight: Font.Bold
                font.pixelSize: 30 * root.u
                font.letterSpacing: 4 * root.u
                color: "#6a6a6a"
            }
            TextInput {
                id: pw
                x: 36 * root.u
                width: parent.width - 80 * root.u
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -3 * root.u
                echoMode: TextInput.Password
                passwordCharacter: "●"
                font.family: "Antonio"
                font.weight: Font.Bold
                font.pixelSize: 30 * root.u
                font.letterSpacing: 4 * root.u
                color: root.paper
                selectionColor: root.red
                cursorDelegate: Rectangle { width: 3 * root.u; color: root.red }
                clip: true
                enabled: !root.busy
                onAccepted: root.login()
                Keys.onEscapePressed: pw.text = ""
                Keys.onTabPressed: root.nextUser()
                onTextChanged: root.failed = false
            }
        }

        // go
        SlabButton {
            y: 190 * root.u
            width: parent.width
            height: 76 * root.u
            label: root.busy ? "..." : "LOG IN"
            fill: root.red
            hoverFill: root.paper
            textColor: root.paper
            hoverText: root.ink
            outline: root.paper
            shadow: root.ink
            fontSize: 52 * root.u
            skew: 12 * root.u
            shadowOffset: 6 * root.u
            onClicked: root.login()
        }

        // session picker
        SlabButton {
            y: 290 * root.u
            x: (parent.width - width) / 2
            width: 300 * root.u
            height: 46 * root.u
            label: "WM  " + root.sessName.toUpperCase()
            fontFamily: "Antonio"
            fontSize: 20 * root.u
            fill: root.ink
            hoverFill: root.paper
            textColor: root.paper
            hoverText: root.ink
            outline: root.paper
            shadow: root.red
            skew: 8 * root.u
            shadowOffset: 4 * root.u
            onClicked: root.nextSession()
        }

        // sticker
        Burst {
            x: parent.width - 62 * root.u
            y: 168 * root.u
            width: 118 * root.u
            height: 118 * root.u
            rotation: 12
            fill: root.paper
            edge: root.ink
            rim: root.red
            spikes: 12
            seed: 5

            Text {
                anchors.centerIn: parent
                text: "GO!"
                font.family: "Bebas Neue"
                font.pixelSize: 40 * root.u
                color: root.ink
            }
        }
    }

    // access denied
    Ransom {
        visible: root.failed
        x: (root.width - width) / 2
        y: 548 * root.u
        text: "ACCESS DENIED"
        size: 30 * root.u
        autoGlitch: true
        forceStyle: 2
        red: root.red
        ink: root.ink
        paper: root.paper
    }

    // ── clock: poster digits, ransom day, typewriter date strip ─────────────
    Item {
        id: clock
        anchors.right: parent.right
        anchors.rightMargin: 64 * root.u
        y: 36 * root.u
        width: 330 * root.u
        height: 200 * root.u

        readonly property string hh: Qt.formatDateTime(root.now, "hh")
        readonly property string mm: Qt.formatDateTime(root.now, "mm")
        readonly property bool blink: root.now.getSeconds() % 2 === 0

        component Poster: Item {
            id: pst
            property string t
            property color face
            property color back: root.ink
            property real fs: 128 * root.u
            width: front.implicitWidth
            height: front.implicitHeight
            Text { x: 7 * root.u; y: 7 * root.u; text: pst.t; color: pst.back; font: front.font }
            Text {
                id: front
                text: pst.t
                color: pst.face
                font.family: "Bebas Neue"
                font.pixelSize: pst.fs
                style: Text.Outline
                styleColor: root.ink
            }
        }

        Row {
            id: digits
            anchors.right: parent.right
            rotation: -5
            spacing: 6 * root.u

            Poster { t: clock.hh; face: root.paper; back: root.red }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 4 * root.u
                spacing: 22 * root.u
                z: 2
                opacity: clock.blink ? 1 : 0.35
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Rectangle { width: 17 * root.u; height: 17 * root.u; color: root.paper; border.color: root.ink; border.width: 3 * root.u }
                Rectangle { width: 17 * root.u; height: 17 * root.u; color: root.paper; border.color: root.ink; border.width: 3 * root.u }
            }
            Poster { t: clock.mm; face: root.red; back: root.paper }
        }

        // day in ransom scraps, pasted over the bottom-left of the digits
        RansomCut {
            x: digits.x - 18 * root.u
            y: 108 * root.u
            text: Qt.formatDateTime(root.now, "dddd")
            size: 30 * root.u
            seed: 41
            red: root.red
            ink: root.ink
            paper: root.paper
        }

        // typewriter label strip
        Slab {
            id: dateSlab
            anchors.right: parent.right
            anchors.rightMargin: 6 * root.u
            y: 176 * root.u
            width: dateText.contentWidth + 36 * root.u + shadowOffset
            height: 34 * root.u
            rotation: 3
            fill: root.paper
            outline: root.ink
            shadow: root.red
            skew: 0
            shadowOffset: 4 * root.u
            outlineWidth: 2 * root.u
            Text {
                id: dateText
                // centre inside the white card (the slab's area minus its shadow)
                x: (dateSlab.width - dateSlab.shadowOffset - contentWidth) / 2
                y: (dateSlab.height - dateSlab.shadowOffset - contentHeight) / 2
                text: "// " + Qt.formatDateTime(root.now, "dd MMM yyyy").toUpperCase()
                font.family: "Liberation Mono"
                font.weight: Font.Bold
                font.pixelSize: 17 * root.u
                color: root.ink
            }
        }
    }

    // ── power ──────────────────────────────────────────────────────────────
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 72 * root.u
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 56 * root.u
        spacing: 20 * root.u
        scale: 0.85
        transformOrigin: Item.BottomRight

        SlabButton {
            visible: sddm.canSuspend
            width: 130 * root.u
            height: 48 * root.u
            label: "SLEEP"
            fontFamily: "Antonio"
            fontSize: 22 * root.u
            fill: root.ink
            hoverFill: root.paper
            textColor: root.paper
            hoverText: root.ink
            outline: root.paper
            shadow: root.red
            skew: 8 * root.u
            shadowOffset: 4 * root.u
            onClicked: sddm.suspend()
        }
        SlabButton {
            visible: sddm.canReboot
            width: 130 * root.u
            height: 48 * root.u
            label: "REBOOT"
            fontFamily: "Antonio"
            fontSize: 22 * root.u
            fill: root.ink
            hoverFill: root.paper
            textColor: root.paper
            hoverText: root.ink
            outline: root.paper
            shadow: root.red
            skew: 8 * root.u
            shadowOffset: 4 * root.u
            onClicked: sddm.reboot()
        }
        SlabButton {
            visible: sddm.canPowerOff
            width: 150 * root.u
            height: 48 * root.u
            label: "SHUT DOWN"
            fontFamily: "Antonio"
            fontSize: 22 * root.u
            fill: root.red
            hoverFill: root.paper
            textColor: root.paper
            hoverText: root.ink
            outline: root.paper
            shadow: root.ink
            skew: 8 * root.u
            shadowOffset: 4 * root.u
            onClicked: sddm.powerOff()
        }
    }

    // photocopy grain
    Image {
        anchors.fill: parent
        source: "grain.png"
        fillMode: Image.Tile
        opacity: 0.55
        smooth: false
    }
}
