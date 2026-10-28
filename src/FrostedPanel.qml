import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    required property Item backdrop
    required property point sampleOrigin

    ShaderEffectSource {
        id: sample
        sourceItem: root.backdrop
        sourceRect: Qt.rect(root.sampleOrigin.x, root.sampleOrigin.y, root.width, root.height)
        hideSource: false
        live: true
        visible: false
    }

    Rectangle {
        id: blurMask
        anchors.fill: parent
        radius: root.radius
        color: "white"
        layer.enabled: true
        visible: false
    }

    MultiEffect {
        anchors.fill: parent
        z: -1
        source: sample
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 32
        blur: 1
        maskEnabled: true
        maskSource: blurMask
    }
}
