import QtQuick

// RainLayer �?雨丝粒子
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    // === 雨参�?===
    property real intensity: 0.0
    property int variant: 0
    property real windSpeed: 0.1
    property real transitionProgress: 0.0
    property real exposure: 1.0
    property int particleLimit: 120

    fragmentShader: "qrc:/shaders/rain.frag.qsb"

    Behavior on transitionProgress {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    Behavior on intensity {
        NumberAnimation {
            duration: transitionCtrl.fadeInEnabled ? 400 : 0
            easing.type: Easing.InOutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "transparent"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[RainLayer] ShaderEffect Error")
        }
    }
}
