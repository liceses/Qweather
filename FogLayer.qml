import QtQuick

// FogLayer — 雾/霾/沙尘
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    // === 雾参数 ===
    property real intensity: 0.0
    property int variant: 0
    property real windSpeed: 0.1
    property real transitionProgress: 1.0

    fragmentShader: "qrc:/shaders/fog.frag.qsb"

    Behavior on transitionProgress {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "transparent"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[FogLayer] ShaderEffect Error")
        }
    }
}
