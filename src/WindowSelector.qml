pragma ComponentBehavior: Bound

import QtQuick


Item {
    id: root

    property var monitor
    property var windows: []

    signal regionSelected(real x, real y, real width, real height)

    // Shader customization properties
    property real dimOpacity: 0.6
    property real borderRadius: 10.0
    // The Rectangle draws the single 1px outline; do not add a shader stroke.
    property real outlineThickness: 0.0
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

    }

    function checkWindow(mouseX, mouseY) {
        selectionWidth = 0
        selectionHeight = 0
        const workspace = monitor.specialWorkspace.id !== 0 ? monitor.specialWorkspace.id : monitor.activeWorkspace.id
        const candidates = windows.filter(w => w.mapped && !w.hidden && (w.workspace.id === workspace || (w.pinned && w.monitor === monitor.id)))
        candidates.sort((a, b) => Number(b.fullscreen > 0) - Number(a.fullscreen > 0) || Number(b.floating) - Number(a.floating) || a.focusHistoryID - b.focusHistoryID)
        for (const w of candidates) {
            const x = Math.max(0, w.at[0] - monitor.x)
            const y = Math.max(0, w.at[1] - monitor.y)
            const right = Math.min(root.width, w.at[0] - monitor.x + w.size[0])
            const bottom = Math.min(root.height, w.at[1] - monitor.y + w.size[1])
            if (mouseX >= x && mouseX < right && mouseY >= y && mouseY < bottom) {
                selectionX = x
                selectionY = y
                selectionWidth = right - x
                selectionHeight = bottom - y
                return
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        z: 3
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onExited: { root.selectionWidth = 0; root.selectionHeight = 0 }

        onPositionChanged: (mouse) => {
            root.checkWindow(mouse.x, mouse.y)
        }

        onReleased: (mouse) => {
            root.checkWindow(mouse.x, mouse.y)
            if (root.selectionWidth > 1 && root.selectionHeight > 1 && mouse.x >= root.selectionX && mouse.x <= root.selectionX + root.selectionWidth &&
                mouse.y >= root.selectionY && mouse.y <= root.selectionY + root.selectionHeight) {
                root.regionSelected(
                    Math.round(root.selectionX),
                    Math.round(root.selectionY),
                    Math.round(root.selectionWidth),
                    Math.round(root.selectionHeight)
                )
            }
        }
    }
}
