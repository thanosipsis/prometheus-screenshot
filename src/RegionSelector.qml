import QtQuick

Item {
    id: root

    signal regionSelected(real x, real y, real width, real height)

    // Shader customization properties
    property real dimOpacity: 0.6
    property real borderRadius: 10.0
    property real outlineThickness: 2.0
    property color outlineColor: "#fcfcfc"
    property color selectionFillColor: "transparent"
    property color labelBackground: "#b8000000"
    property color labelBorderColor: "#252d2f"
    property color labelForeground: "#f5f5f5"
    property string labelText: ""
    property string fontFamily: "JetBrainsMono Nerd Font"
    property url fragmentShader: Qt.resolvedUrl("../shaders/dimming.frag.qsb")

    property point startPos
    property real selectionX: 0
    property real selectionY: 0
    property real selectionWidth: 0
    property real selectionHeight: 0

    // Shader overlay
    ShaderEffect {
        anchors.fill: parent
        z: 0

        property vector4d selectionRect: Qt.vector4d(
            root.selectionX,
            root.selectionY,
            root.selectionWidth,
            root.selectionHeight
        )
        property real dimOpacity: root.dimOpacity
        property vector2d screenSize: Qt.vector2d(root.width, root.height)
        property real borderRadius: root.borderRadius
        property real outlineThickness: root.outlineThickness

        fragmentShader: root.fragmentShader
    }

    Rectangle {
        id: selectionFrame
        x: root.selectionX
        y: root.selectionY
        width: root.selectionWidth
        height: root.selectionHeight
        visible: width > 1 && height > 1
        z: 1
        radius: root.borderRadius
        color: root.selectionFillColor
        border.width: 1
        border.color: root.outlineColor

        Rectangle {
            anchors.fill: parent
            anchors.margins: 4
            radius: Math.max(1, root.borderRadius - 1)
            color: "transparent"
            border.width: 1
            border.color: root.labelBorderColor
            opacity: 0.72
        }
    }

    Rectangle {
        id: selectionBadge
        x: Math.min(Math.max(12, root.selectionX), Math.max(12, root.width - width - 12))
        y: root.selectionY > height + 14 ? root.selectionY - height - 8 : root.selectionY + 8
        width: badgeText.implicitWidth + 18
        height: 24
        visible: selectionFrame.visible && root.labelText.length > 0
        z: 2
        radius: 3
        color: root.labelBackground
        border.width: 1
        border.color: root.labelBorderColor

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.labelText + "  " + Math.round(root.selectionWidth) + "x" + Math.round(root.selectionHeight)
            color: root.labelForeground
            font.family: root.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        z: 3

        onPressed: (mouse) => {
            root.startPos = Qt.point(mouse.x, mouse.y)
            root.selectionX = mouse.x
            root.selectionY = mouse.y
            root.selectionWidth = 0
            root.selectionHeight = 0
        }

        onPositionChanged: (mouse) => {
            if (pressed) {
                const x = Math.min(root.startPos.x, mouse.x)
                const y = Math.min(root.startPos.y, mouse.y)
                const width = Math.abs(mouse.x - root.startPos.x)
                const height = Math.abs(mouse.y - root.startPos.y)

                root.selectionX = x
                root.selectionY = y
                root.selectionWidth = width
                root.selectionHeight = height
            }
        }

        cursorShape: Qt.CrossCursor
        onReleased: (mouse) => {
            const x = Math.max(0, Math.min(root.startPos.x, mouse.x))
            const y = Math.max(0, Math.min(root.startPos.y, mouse.y))
            const right = Math.min(root.width, Math.max(root.startPos.x, mouse.x))
            const bottom = Math.min(root.height, Math.max(root.startPos.y, mouse.y))
            if (right - x >= 2 && bottom - y >= 2)
                root.regionSelected(x, y, right - x, bottom - y)
        }
    }
}
