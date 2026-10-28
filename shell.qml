pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import "src"
import "theme" as PrometheusTheme

FreezeScreen {
    id: root
    visible: !busy
    property var context: JSON.parse(Quickshell.env("PROMETHEUS_CAPTURE_CONTEXT") || "{}")
    targetScreen: Quickshell.screens.find(s => s.name === root.context.monitor?.name) || Quickshell.screens[0]
    imagePath: context.image || ""
    Component.onCompleted: {
        if (!context.image) {
            console.error("Start with launch.py or prometheus-screenshot to freeze the display first.")
            Qt.quit()
        }
    }

    PrometheusTheme.Theme { id: theme }
    property string mode: "region"
    property bool busy: false
    property string errorText: ""
    readonly property string hint: errorText || (mode === "region" ? "Drag to capture an area" : mode === "window" ? "Click a window to capture it" : "Capture the entire display")

    Settings {
        id: settings
        category: "PrometheusScreenshot"
        location: "file://" + Quickshell.statePath("capture.ini")
        property bool saveToDisk: true
    }

    function selectMode(value) {
        mode = value
        region.selectionWidth = 0
        region.selectionHeight = 0
        windowSelector.selectionWidth = 0
        windowSelector.selectionHeight = 0
    }

    function capture(x, y, width, height) {
        if (busy || width < 2 || height < 2) return
        busy = true
        errorText = ""
        processor.command = ["python3", Quickshell.shellPath("capture.py"), context.image,
            String(x), String(y), String(width), String(height),
            String(root.targetScreen.width), String(root.targetScreen.height), String(settings.saveToDisk)]
        processor.running = true
    }

    Process {
        id: processor
        stderr: StdioCollector { onStreamFinished: if (text) console.error(text) }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) Qt.quit()
            else {
                root.busy = false
                root.errorText = "Capture failed. Try again or press Esc."
            }
        }
    }

    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    Shortcut { sequence: "1"; onActivated: root.selectMode("region") }
    Shortcut { sequence: "2"; onActivated: root.selectMode("window") }
    Shortcut { sequence: "3"; onActivated: root.selectMode("screen") }
    Shortcut { sequence: "S"; onActivated: settings.saveToDisk = !settings.saveToDisk }
    Shortcut {
        sequence: "Return"
        onActivated: {
            if (root.mode === "screen") root.capture(0, 0, root.targetScreen.width, root.targetScreen.height)
            else if (root.mode === "window" && windowSelector.selectionWidth > 1)
                root.capture(windowSelector.selectionX, windowSelector.selectionY, windowSelector.selectionWidth, windowSelector.selectionHeight)
        }
    }

    RegionSelector {
        id: region
        anchors.fill: parent
        visible: root.mode === "region"
        dimOpacity: 0.48
        borderRadius: 2
        outlineColor: theme.ink
        selectionFillColor: "transparent"
        labelText: "AREA"
        fontFamily: theme.fontFamily
        onRegionSelected: (x, y, width, height) => root.capture(x, y, width, height)
    }

    WindowSelector {
        id: windowSelector
        anchors.fill: parent
        visible: root.mode === "window"
        monitor: root.context.monitor
        windows: root.context.windows || []
        dimOpacity: 0.48
        borderRadius: 4
        outlineColor: theme.ink
        selectionFillColor: "transparent"
        fontFamily: theme.fontFamily
        onRegionSelected: (x, y, width, height) => root.capture(x, y, width, height)
    }

    Rectangle {
        anchors.fill: parent
        visible: root.mode === "screen"
        color: "transparent"
        radius: 4
        border.width: 1
        border.color: theme.ink
    }

    ColumnLayout {
        id: toolbarStack
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 32
        spacing: 12

        FrostedPanel {
            id: hintPanel
            backdrop: root.captureBackground
            sampleOrigin: Qt.point(toolbarStack.x + x, toolbarStack.y + y)
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: hintLabel.implicitWidth + 28
            implicitHeight: 32
            radius: 4
            color: theme.panelTinted
            border.width: 1
            border.color: theme.line
            Text {
                id: hintLabel
                anchors.centerIn: parent
                text: root.hint
                color: root.errorText ? theme.danger : theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }

        FrostedPanel {
            backdrop: root.captureBackground
            sampleOrigin: Qt.point(toolbarStack.x + x, toolbarStack.y + y)
            implicitWidth: controls.implicitWidth + 24
            implicitHeight: 54
            radius: 4
            color: theme.panelTinted
            border.width: 1
            border.color: theme.line

            // Consume gaps as well as buttons so the selector never starts behind the toolbar.
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            RowLayout {
                id: controls
                anchors.centerIn: parent
                spacing: 12
                Repeater {
                    model: [
                        {mode: "region", icon: "region", label: "Drag", key: "1"},
                        {mode: "window", icon: "window", label: "Window", key: "2"},
                        {mode: "screen", icon: "screen", label: "Full screen", key: "3"}
                    ]
                    Button {
                        id: modeButton
                        required property var modelData
                        implicitWidth: contentItem.implicitWidth + 24
                        implicitHeight: 38
                        leftPadding: 12
                        rightPadding: 12
                        topPadding: 8
                        bottomPadding: 8
                        focusPolicy: Qt.NoFocus
                        Accessible.name: modelData.label
                        onClicked: root.selectMode(modelData.mode)
                        background: Rectangle {
                            radius: 3
                            color: modeButton.down ? "#1f2d30" : root.mode === modeButton.modelData.mode ? "#172123" : modeButton.hovered ? theme.workspaceHover : "#070d0e"
                            border.width: 1
                            border.color: root.mode === modeButton.modelData.mode ? theme.accent : "#334044"
                        }
                        contentItem: RowLayout {
                            spacing: 10
                            Image {
                                source: Quickshell.shellPath("icons/" + modeButton.modelData.icon + ".svg")
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                opacity: root.mode === modeButton.modelData.mode ? 1 : 0.72
                            }
                            Text {
                                text: modeButton.modelData.label
                                color: root.mode === modeButton.modelData.mode ? theme.accent : theme.prometheusInk
                                font.family: theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                renderType: Text.NativeRendering
                            }
                            Text {
                                text: modeButton.modelData.key
                                color: theme.muted
                                font.family: theme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }
                }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 24; color: theme.line }
                Button {
                    id: saveButton
                    implicitWidth: 108
                    implicitHeight: 38
                    focusPolicy: Qt.NoFocus
                    text: settings.saveToDisk ? "Save: On" : "Save: Off"
                    Accessible.name: "Save to Pictures/Screenshots"
                    onClicked: settings.saveToDisk = !settings.saveToDisk
                    background: Rectangle {
                        radius: 3
                        color: saveButton.down ? "#172123" : saveButton.hovered ? theme.workspaceHover : "#070d0e"
                        border.width: 1
                        border.color: settings.saveToDisk ? theme.accent : "#334044"
                    }
                    contentItem: Text {
                        text: saveButton.text
                        color: settings.saveToDisk ? theme.accent : theme.muted
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                Button {
                    id: captureButton
                    visible: root.mode === "screen"
                    implicitWidth: 110
                    implicitHeight: 38
                    focusPolicy: Qt.NoFocus
                    onClicked: root.capture(0, 0, root.targetScreen.width, root.targetScreen.height)
                    background: Rectangle {
                        radius: 3
                        color: captureButton.down ? "#2b3638" : captureButton.hovered ? "#243033" : "#1a2426"
                        border.width: 1
                        border.color: "#334044"
                    }
                    contentItem: Text {
                        text: "Capture ↵"
                        color: theme.prometheusInk
                        font.family: theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

    }
}
