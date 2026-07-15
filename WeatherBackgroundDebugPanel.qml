import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// WeatherBackgroundDebugPanel — 浮动调试面板
// 快捷键: Ctrl+Shift+B 切换显示
// Debug 模式: 所有滑块可调，覆盖 SkyState
// Auto 模式: 只读显示
Rectangle {
    id: panel
    visible: false
    z: 100
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 12
    width: 320
    height: Math.min(580, parent.height - 24)
    color: "#e8e8e8"
    radius: 8
    border.color: "#bbb"
    border.width: 1

    // 快捷键显示/隐藏
    Shortcut {
        sequence: "Ctrl+Shift+B"
        onActivated: {
            panel.visible = !panel.visible
            if (panel.visible) {
                console.log("[DebugPanel] opened")
                // 进入 debug 模式时自动激活
                if (backgroundManager.controlMode !== 1)
                    backgroundManager.enterDebugMode()
            } else {
                console.log("[DebugPanel] closed")
                // 关闭面板时退出 debug 模式
                if (backgroundManager.controlMode === 1)
                    backgroundManager.exitDebugMode()
            }
        }
    }

    // 关闭按钮
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4
        width: 24; height: 24
        radius: 12
        color: "#d44"
        Text {
            anchors.centerIn: parent
            text: "✕"
            color: "white"
            font.pixelSize: 14
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                panel.visible = false
                if (backgroundManager.controlMode === 1)
                    backgroundManager.exitDebugMode()
                console.log("[DebugPanel] closed by button")
            }
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 32
        contentHeight: contentCol.implicitHeight + 16
        clip: true

        ColumnLayout {
            id: contentCol
            width: parent.width - 8
            spacing: 6

            // === 标题 ===
            Text {
                text: "☰ 调试面板"
                font.pixelSize: 15
                font.bold: true
                color: "#333"
            }

            // === 模式切换 ===
            RowLayout {
                spacing: 8
                Text { text: "模式:"; color: "#555" }
                Button {
                    text: "● Auto"
                    checked: backgroundManager.controlMode === 0
                    onClicked: {
                        if (backgroundManager.controlMode === 1)
                            backgroundManager.exitDebugMode()
                    }
                }
                Button {
                    text: "◉ Debug"
                    checked: backgroundManager.controlMode === 1
                    onClicked: {
                        if (backgroundManager.controlMode === 0)
                            backgroundManager.enterDebugMode()
                    }
                }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === Layer 状态 ===
            Text { text: "Layer 状态"; font.bold: true; color: "#555" }

            GridLayout {
                columns: 3
                columnSpacing: 8; rowSpacing: 2

                Repeater {
                    model: [
                        { label: "Sky",      active: true },
                        { label: "Cloud",    active: transitionCtrl.cloudActive, tp: transitionCtrl.cloudTP },
                        { label: "Weather",  active: transitionCtrl.weatherActive, tp: transitionCtrl.weatherTP },
                        { label: "Fog",      active: transitionCtrl.fogActive, tp: transitionCtrl.fogTP },
                        { label: "Lightning",active: transitionCtrl.lightningActive }
                    ]
                    delegate: Item {
                        implicitWidth: 90; implicitHeight: 20
                        Rectangle {
                            width: 10; height: 10; anchors.verticalCenter: parent.verticalCenter
                            radius: 5; color: modelData.active ? "#4a4" : "#aaa"
                        }
                        Text {
                            x: 16; anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (modelData.tp !== undefined && modelData.active)
                                    return modelData.label + " " + modelData.tp.toFixed(2)
                                return modelData.label + (modelData.active ? " ●" : " ○")
                            }
                            font.pixelSize: 12; color: "#444"
                        }
                    }
                }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 参数滑块（使用直接属性绑定 — Q_GADGET 不支持 bracket 访问） ===
            Text { text: "参数"; font.bold: true; color: "#555" }

            // 云覆盖率
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "云覆盖率"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldCC; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.cloudCoverage
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("cloudCoverage", value); console.log("[DebugPanel] cloudCoverage = " + value.toFixed(3)) }
                }
                Text { text: sldCC.value.toFixed(2); width: 40; font.pixelSize: 11; color: "#888" }
            }
            // 雨强度
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雨强度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldRI; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.rainIntensity
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("rainIntensity", value); console.log("[DebugPanel] rainIntensity = " + value.toFixed(3)) }
                }
                Text { text: sldRI.value.toFixed(2); width: 40; font.pixelSize: 11; color: "#888" }
            }
            // 雪强度
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雪强度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSI; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.snowIntensity
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("snowIntensity", value); console.log("[DebugPanel] snowIntensity = " + value.toFixed(3)) }
                }
                Text { text: sldSI.value.toFixed(2); width: 40; font.pixelSize: 11; color: "#888" }
            }
            // 雾密度
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雾密度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldFD; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.fogDensity
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("fogDensity", value); console.log("[DebugPanel] fogDensity = " + value.toFixed(3)) }
                }
                Text { text: sldFD.value.toFixed(2); width: 40; font.pixelSize: 11; color: "#888" }
            }
            // 星星
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "星星"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSV; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.starVisibility
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("starVisibility", value); console.log("[DebugPanel] starVisibility = " + value.toFixed(3)) }
                }
                Text { text: sldSV.value.toFixed(2); width: 40; font.pixelSize: 11; color: "#888" }
            }
            // 太阳高度
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "太阳高度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSA; Layout.fillWidth: true; from: -10; to: 90
                    value: backgroundManager.skyState.solarAltitude
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("solarAltitude", value); console.log("[DebugPanel] solarAltitude = " + value.toFixed(3)) }
                }
                Text { text: sldSA.value.toFixed(1) + "°"; width: 40; font.pixelSize: 11; color: "#888" }
            }
            // 黄昏因子
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "黄昏因子"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldTF; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.twilightFactor
                    enabled: backgroundManager.controlMode === 1
                    onMoved: { backgroundManager.setDebugField("twilightFactor", value); console.log("[DebugPanel] twilightFactor = " + value.toFixed(3)) }
                }
                Text { text: sldTF.value.toFixed(2); width: 40; font.pixelSize: 11; color: "#888" }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 天文信息 (只读) ===
            Text { text: "天文 (只读)"; font.bold: true; color: "#555" }

            GridLayout {
                columns: 2
                columnSpacing: 8; rowSpacing: 2

                Text { text: "太阳高度:"; font.pixelSize: 11; color: "#666" }
                Text { text: backgroundManager.skyState.solarAltitude.toFixed(1) + "°"; font.pixelSize: 11; color: "#333" }

                Text { text: "月亮高度:"; font.pixelSize: 11; color: "#666" }
                Text { text: backgroundManager.skyState.moonAltitude.toFixed(1) + "°"; font.pixelSize: 11; color: "#333" }

                Text { text: "月相:"; font.pixelSize: 11; color: "#666" }
                Text { text: backgroundManager.skyState.moonPhase.toFixed(0); font.pixelSize: 11; color: "#333" }

                Text { text: "月光:"; font.pixelSize: 11; color: "#666" }
                Text { text: (backgroundManager.skyState.moonIllum * 100).toFixed(0) + "%"; font.pixelSize: 11; color: "#333" }

                Text { text: "黄昏:"; font.pixelSize: 11; color: "#666" }
                Text { text: backgroundManager.skyState.twilightFactor.toFixed(3); font.pixelSize: 11; color: "#333" }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 快捷操作 ===
            Text { text: "快捷操作"; font.bold: true; color: "#555" }
            RowLayout {
                spacing: 4
                Button {
                    text: "晴天"
                    onClicked: {
                        backgroundManager.setDebugField("cloudCoverage", 0)
                        backgroundManager.setDebugField("rainIntensity", 0)
                        backgroundManager.setDebugField("snowIntensity", 0)
                        backgroundManager.setDebugField("fogDensity", 0)
                        backgroundManager.setDebugField("starVisibility", 0)
                        backgroundManager.setDebugField("twilightFactor", 0)
                        backgroundManager.setDebugField("solarAltitude", 60)
                        console.log("[DebugPanel] quick: sunny")
                    }
                }
                Button {
                    text: "多云"
                    onClicked: {
                        backgroundManager.setDebugField("cloudCoverage", 0.6)
                        backgroundManager.setDebugField("starVisibility", 0)
                        backgroundManager.setDebugField("solarAltitude", 45)
                        console.log("[DebugPanel] quick: cloudy")
                    }
                }
                Button {
                    text: "下雨"
                    onClicked: {
                        backgroundManager.setDebugField("cloudCoverage", 0.8)
                        backgroundManager.setDebugField("rainIntensity", 0.6)
                        backgroundManager.setDebugField("snowIntensity", 0)
                        backgroundManager.setDebugField("fogDensity", 0)
                        backgroundManager.setDebugField("starVisibility", 0)
                        backgroundManager.setDebugField("twilightFactor", 0)
                        console.log("[DebugPanel] quick: rainy")
                    }
                }
                Button {
                    text: "夜晚"
                    onClicked: {
                        backgroundManager.setDebugField("solarAltitude", -20)
                        backgroundManager.setDebugField("starVisibility", 0.8)
                        backgroundManager.setDebugField("cloudCoverage", 0)
                        backgroundManager.setDebugField("rainIntensity", 0)
                        backgroundManager.setDebugField("snowIntensity", 0)
                        backgroundManager.setDebugField("fogDensity", 0)
                        console.log("[DebugPanel] quick: night")
                    }
                }
            }

            // 状态转储
            Button {
                text: "📋 转储状态"
                Layout.fillWidth: true
                onClicked: {
                    var dump = backgroundManager.dumpState()
                    console.log(dump)
                    console.log(transitionCtrl.dumpState())
                }
            }
        }
    }

    // 弹出提示
    Component.onCompleted: {
        console.log("[DebugPanel] ready — press Ctrl+Shift+B to toggle")
    }
}
