import QtQuick

// SkyLayer — 天空渐变 + 太阳光晕 + 月亮 SDF + 星星
// 始终渲染，无 transitionProgress
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // === 通用 ===
    property real time: 0.0

    // === 天文 ===
    property real solarAltitude: 45.0
    property real solarAzimuth: 180.0
    property real moonAltitude: 30.0
    property real moonAzimuth: 90.0
    property real moonPhase: 4.0
    property real moonIllum: 1.0

    // === 大气 ===
    property color zenithColor: "#4a90d9"
    property color horizonColor: "#87ceeb"
    property color ambientColor: "#c8e0f0"
    property real exposure: 1.0
    property real twilightFactor: 0.0

    // === 星星 ===
    property real starVisibility: 0.0

    // === 平滑过渡 ===
    Behavior on zenithColor  { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on horizonColor { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on ambientColor { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on exposure     { NumberAnimation   { duration: 600; easing.type: Easing.OutCubic } }

    // === 视差 ===
    property real parallaxX: 0.0
    property real parallaxY: 0.0

    fragmentShader: "qrc:/shaders/sky.frag.qsb"

    // 容错
    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "#4a90d9"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[SkyLayer] ShaderEffect Error — using fallback blue")
        }
    }
}
