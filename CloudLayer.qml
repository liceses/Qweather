import QtQuick

// CloudLayer - 2~3 layer fBM cloud noise drift
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    property real time: 0.0
    property real cloudCoverage: 0.0
    property real cloudOpacity: 1.0
    property int variant: 1
    property real windSpeed: 0.1
    property real transitionProgress: 0.0

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
