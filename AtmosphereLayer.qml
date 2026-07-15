import QtQuick

// AtmosphereLayer — twilight 散射色调 + 曝光控制
// 始终渲染，半透明叠加
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    // === 大气 ===
    property color zenithColor: "#4a90d9"
    property color horizonColor: "#87ceeb"
    property color ambientColor: "#c8e0f0"
    property real exposure: 1.0
    property real twilightFactor: 0.0

    // === 平滑过渡 ===
    Behavior on zenithColor  { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on horizonColor { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on ambientColor { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on exposure     { NumberAnimation   { duration: 600; easing.type: Easing.OutCubic } }

    fragmentShader: "qrc:/shaders/atmosphere.frag.qsb"

    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "transparent"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[AtmosphereLayer] ShaderEffect Error")
        }
    }
}
