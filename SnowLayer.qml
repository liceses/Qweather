import QtQuick

// SnowLayer — 雪花粒子
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    // === 雪参数 ===
    property real intensity: 0.0
    property int variant: 0
    property real windSpeed: 0.1
    property real transitionProgress: 1.0
    property int particleLimit: 60

    fragmentShader: "qrc:/shaders/snow.frag.qsb"

    Behavior on transitionProgress {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "transparent"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[SnowLayer] ShaderEffect Error")
        }
    }
}
