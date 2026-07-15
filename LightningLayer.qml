import QtQuick

// LightningLayer — 全屏间歇闪电闪烁
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    fragmentShader: "qrc:/shaders/lightning.frag.qsb"

    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "transparent"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[LightningLayer] ShaderEffect Error")
        }
    }
}
