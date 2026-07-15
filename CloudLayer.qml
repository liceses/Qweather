import QtQuick

// CloudLayer — 2~3 层 fBM 云噪声漂移
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    // === 云参数 ===
    property real cloudCoverage: 0.0
    property real cloudOpacity: 1.0
    property int variant: 1
    property real windSpeed: 0.1
    property real transitionProgress: 1.0

    fragmentShader: "qrc:/shaders/cloud.frag.qsb"

    // transitionProgress 平滑
    Behavior on transitionProgress {
        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
    }

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
