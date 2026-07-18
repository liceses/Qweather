import QtQuick

// [SkyLayer] — Sky gradient + sun glow + moon SDF + stars / 天空渐变 + 太阳光晕 + 月相 SDF + 星星
// Always rendered, no transitionProgress / 始终渲染，无 transitionProgress
ShaderEffect {
    id: effect
    anchors.fill: parent
    opacity: 1.0

    // [Common] / 通用
    property real time: 0.0

    // [Astronomical] / 天文参数
    property real solarAltitude: 45.0
    property real solarAzimuth: 180.0
    property real moonAltitude: 30.0
    property real moonAzimuth: 90.0
    property real moonPhase: 4.0
    property real moonIllum: 1.0

    // [Atmospheric] / 大气参数
    property color zenithColor: "#4a90d9"
    property color horizonColor: "#87ceeb"
    property color ambientColor: "#c8e0f0"
    property real exposure: 1.0
    property real twilightFactor: 0.0

    // [Stars] / 星星
    property real starVisibility: 0.0

    // [Smooth transitions] / 平滑过渡动画
    Behavior on zenithColor  { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on horizonColor { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on ambientColor { ColorAnimation { duration: 800; easing.type: Easing.OutCubic } }
    Behavior on exposure     { NumberAnimation   { duration: 600; easing.type: Easing.OutCubic } }

    // [Parallax] / 视差偏移
    property real parallaxX: 0.0
    property real parallaxY: 0.0

    fragmentShader: "qrc:/shaders/sky.frag.qsb"

    // [Fallback — solid blue when shader fails] / 容错：着色器编译失败时显示纯蓝色
    Rectangle {
        anchors.fill: parent
        visible: effect.status !== ShaderEffect.Compiled
        color: "#4a90d9"
        Component.onCompleted: {
            if (effect.status === ShaderEffect.Error)
                console.warn("[SkyLayer] ShaderEffect Error — using fallback blue / 使用蓝色容错")
        }
    }
}
