import QtQuick

// [RainLayer] — Rain streak particles / 雨丝粒子
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // [Common] / 通用
    property real time: 0.0

    // [Rain parameters] / 雨参数
    property real intensity: 0.0
    // [Variant: 0=normal, 1=thunderstorm, 2=hail] / 变体：0=普通，1=雷暴，2=冰雹
    property int variant: 0
    // [Wind speed affecting rain tilt] / 风速，影响雨丝倾斜
    property real windSpeed: 0.1
    // [Fade-in transition progress 0~1] / 淡入过渡进度 0~1
    property real transitionProgress: 0.0
    // [Exposure compensation] / 曝光补偿
    property real exposure: 1.0
    // [Maximum number of particles] / 最大粒子数
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

    // [Fallback] / 容错
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
