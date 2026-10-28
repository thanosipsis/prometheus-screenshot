import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    property var targetScreen: Quickshell.screens[0]
    property string imagePath: ""
    readonly property Item captureBackground: frozen
    readonly property bool imageLoaded: frozen.status === Image.Ready
    screen: targetScreen
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "prometheus-screenshot"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Image {
        id: frozen
        anchors.fill: parent
        source: root.imagePath ? "file://" + root.imagePath : ""
        fillMode: Image.Stretch
        onStatusChanged: {
            if (status === Image.Error) Qt.quit()
        }
        z: -1
    }
}
