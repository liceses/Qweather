import QtQuick

// WeatherBackground — Layer 栈容器 + 视差
// 由 C++ TransitionController 控制各 Layer 的 active 状态
Item {
    id: bgRoot
    anchors.fill: parent

    // ===== 视差 =====
    // 鼠标位置由 Main.qml 中的父级 MouseArea 驱动，见 Main.qml
    property double parallaxX: 0.0
    property double parallaxY: 0.0

    // ===== Layer 栈 (z-ordered) =====
    // SkyLayer + AtmosphereLayer: 始终渲染
    SkyLayer {
        z: 0
        time: globalClock.elapsed
        solarAltitude: backgroundManager.skyState.solarAltitude
        solarAzimuth: backgroundManager.skyState.solarAzimuth
        moonAltitude: backgroundManager.skyState.moonAltitude
        moonAzimuth: backgroundManager.skyState.moonAzimuth
        moonPhase: backgroundManager.skyState.moonPhase
        moonIllum: backgroundManager.skyState.moonIllum
        zenithColor: backgroundManager.skyState.zenithColor
        horizonColor: backgroundManager.skyState.horizonColor
        ambientColor: backgroundManager.skyState.ambientColor
        exposure: backgroundManager.skyState.exposure
        twilightFactor: backgroundManager.skyState.twilightFactor
        starVisibility: backgroundManager.skyState.starVisibility
        parallaxX: bgRoot.parallaxX
        parallaxY: bgRoot.parallaxY
    }

    AtmosphereLayer {
        z: 10
        time: globalClock.elapsed
        zenithColor: backgroundManager.skyState.zenithColor
        horizonColor: backgroundManager.skyState.horizonColor
        ambientColor: backgroundManager.skyState.ambientColor
        exposure: backgroundManager.skyState.exposure
        twilightFactor: backgroundManager.skyState.twilightFactor
    }

    // 条件 Layer: 由 TransitionController 控制 active
    Loader {
        z: 20
        anchors.fill: parent
        active: transitionCtrl.cloudActive
        sourceComponent: cloudComp
    }
    Loader {
        z: 30
        anchors.fill: parent
        active: transitionCtrl.weatherActive
        sourceComponent: weatherComp
    }
    Loader {
        z: 40
        anchors.fill: parent
        active: transitionCtrl.fogActive
        sourceComponent: fogComp
    }
    Loader {
        z: 50
        anchors.fill: parent
        active: transitionCtrl.lightningActive
        sourceComponent: lightningComp
    }

    // Layer 组件定义
    Component {
        id: cloudComp
        CloudLayer {
            time: globalClock.elapsed
            cloudCoverage: backgroundManager.skyState.cloudCoverage
            variant: backgroundManager.skyState.cloudVariant
            windSpeed: 0.1
            transitionProgress: transitionCtrl.cloudTP
        }
    }

    Component {
        id: weatherComp
        Item {
            // 包含 Rain 和 Snow，用一个 ShaderEffect
            // 由于 A 和 B 不能同时显示，分开两个 Loader 但共享 active 信号
            RainLayer {
                anchors.fill: parent
                time: globalClock.elapsed
                intensity: backgroundManager.skyState.rainIntensity
                variant: backgroundManager.skyState.weatherVariant
                windSpeed: 0.1
                transitionProgress: transitionCtrl.weatherTP
                particleLimit: 60
                visible: backgroundManager.skyState.rainIntensity > 0.001
            }
            SnowLayer {
                anchors.fill: parent
                time: globalClock.elapsed
                intensity: backgroundManager.skyState.snowIntensity
                variant: backgroundManager.skyState.weatherVariant
                windSpeed: 0.1
                transitionProgress: transitionCtrl.weatherTP
                particleLimit: 60
                visible: backgroundManager.skyState.snowIntensity > 0.001
            }
        }
    }

    Component {
        id: fogComp
        FogLayer {
            time: globalClock.elapsed
            intensity: backgroundManager.skyState.fogDensity
            variant: backgroundManager.skyState.fogVariant
            windSpeed: 0.1
            transitionProgress: transitionCtrl.fogTP
        }
    }

    Component {
        id: lightningComp
        LightningLayer {
            time: globalClock.elapsed
            lightningProb: backgroundManager.skyState.lightningProb
        }
    }

    // 验证输出
    Component.onCompleted: {
        console.log("[WeatherBackground] initialized, layers ready")
    }
}
