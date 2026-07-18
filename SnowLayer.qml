import QtQuick

// [SnowLayer] — Snow particle system / 雪粒子系统
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // [Common] / 通用
    property real time: 0.0

    // [Snow parameters] / 雪参数
    property real intensity: 0.0
    // [Variant: 0=snow, 1=sleet] / 变体：0=雪，1=雨夹雪
    property int variant: 0
    // [Wind speed affecting sway] / 风速，影响雪花摇摆
    property real windSpeed: 0.1
    // [Fade-in transition progress 0~1] / 淡入过渡进度 0~1
    property real transitionProgress: 0.0
    // [Maximum number of particles] / 最大粒子数
    property int particleLimit: 60

    fragmentShader: "qrc:/shaders/snow.frag.qsb"

    Behavior on transitionProgress {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
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
                console.warn("[SnowLayer] ShaderEffect Error")
        }
    }
}
