import QtQuick

// [CloudLayer] — 2~3 layer fBM cloud noise with drift / 2~3 层 fBM 噪声云漂移
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // [Common] / 通用
    property real time: 0.0
    // [Cloud coverage 0~1] / 云覆盖率 0~1
    property real cloudCoverage: 0.0
    // [Cloud opacity multiplier] / 云不透明度乘数
    property real cloudOpacity: 1.0
    // [Cloud variant: 0=sparse, 1=moderate, 2=overcast] / 云变体：0=少云，1=多云，2=阴
    property int variant: 1
    // [Horizontal wind speed] / 水平风速
    property real windSpeed: 0.1
    // [Fade-in transition progress 0~1] / 淡入过渡进度 0~1
    property real transitionProgress: 0.0
    // [Exposure compensation] / 曝光补偿
    property real exposure: 1.0

    fragmentShader: "qrc:/shaders/cloud.frag.qsb"

    Behavior on transitionProgress {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

    Behavior on cloudCoverage {
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
                console.warn("[CloudLayer] ShaderEffect Error")
        }
    }
}
