import QtQuick

// [FogLayer] — Fog / haze / sandstorm overlay / 雾 / 霾 / 沙尘叠加层
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // [Common] / 通用
    property real time: 0.0

    // [Fog parameters] / 雾参数
    property real intensity: 0.0
    // [Variant: 0=fog, 1=haze, 2=sand] / 变体：0=雾，1=霾，2=沙尘
    property int variant: 0
    // [Wind speed affecting drift] / 风速
    property real windSpeed: 0.1
    // [Fade-in transition progress 0~1] / 淡入过渡进度 0~1
    property real transitionProgress: 0.0

    fragmentShader: "qrc:/shaders/fog.frag.qsb"

    Behavior on transitionProgress {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    Behavior on intensity {
        NumberAnimation {
            duration: transitionCtrl.fadeInEnabled ? 400 : 0
            easing.type: Easing.InOutCubic
        }
    }

    // [Fallback] / 容错
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
