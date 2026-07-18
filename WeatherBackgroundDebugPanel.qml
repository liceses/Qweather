import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// [WeatherBackgroundDebugPanel] — Debug control panel for weather system / 天气系统调试控制面板
// All controls submit via commitSkyState({all 17 fields}) / 所有控件通过 commitSkyState({全部 17 字段}) 统一提交
Rectangle {
    id: panel
    visible: false
    z: 100
    anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 12
    width: 360; height: Math.min(700, parent.height - 24)
    border.color: "#bbb"; border.width: 1

    property bool dragging: false
    color: dragging ? Qt.rgba(0.91, 0.91, 0.91, 0.15) : "#e8e8e8"
    Behavior on color { ColorAnimation { duration: 200 } }
    radius: 8

    // [Collect all control values → submit complete SkyState] / 收集所有控件值 → 提交完整 SkyState
    function commit() {
        backgroundManager.commitSkyState({
            solarAltitude:  sldSA.value,
            solarAzimuth:   sldSZ.value,
            moonAltitude:   sldMA.value,
            moonAzimuth:    sldMZ.value,
            moonPhase:      sldMP.value,
            moonIllum:      sldMI.value,
            cloudCoverage:  sldCC.value,
            rainIntensity:  sldRI.value,
            snowIntensity:  sldSI.value,
            fogDensity:     sldFD.value,
            lightningProb:  sldLP.value,
            starVisibility: sldSV.value,
            cloudVariant:   cbCloudV.currentIndex,
            fogVariant:     cbFogV.currentIndex,
            weatherVariant: cbRainV.currentIndex,
            exposure:       sldEX.value,
            twilightFactor: sldTF.value,
            zenithColor:    colorZenith.color,
            horizonColor:   colorHorizon.color,
            ambientColor:   colorAmbient.color
        })
    }

    // [Demo mode — automatic weather & time cycling] / 演示模式——自动循环切换天气和时间
    property bool demoMode: false
    property real demoHour: 0
    property int demoWeatherIdx: 0
    property var demoWeatherList: [100,101,104,300,305,310,302,400,500,502]
    property real demoSpeed: 1.0

    property var wFrom: ({})
    property var wTo: ({})
    property int wLerp: 0
    property int wLerpDur: 40

    function switchWeather(code) {
        var isDay = code < 150
        wFrom = {
            cloudCoverage:  backgroundManager.skyState.cloudCoverage,
            rainIntensity:  backgroundManager.skyState.rainIntensity,
            snowIntensity:  backgroundManager.skyState.snowIntensity,
            fogDensity:     backgroundManager.skyState.fogDensity,
            lightningProb:  backgroundManager.skyState.lightningProb,
            starVisibility: backgroundManager.skyState.starVisibility,
            cloudVariant:   backgroundManager.skyState.cloudVariant,
            fogVariant:     backgroundManager.skyState.fogVariant,
            weatherVariant: backgroundManager.skyState.weatherVariant,
            exposure:       backgroundManager.skyState.exposure
        }
        backgroundManager.updateWeather(code, isDay)
        wTo = {
            cloudCoverage:  backgroundManager.skyState.cloudCoverage,
            rainIntensity:  backgroundManager.skyState.rainIntensity,
            snowIntensity:  backgroundManager.skyState.snowIntensity,
            fogDensity:     backgroundManager.skyState.fogDensity,
            lightningProb:  backgroundManager.skyState.lightningProb,
            starVisibility: backgroundManager.skyState.starVisibility,
            cloudVariant:   backgroundManager.skyState.cloudVariant,
            fogVariant:     backgroundManager.skyState.fogVariant,
            weatherVariant: backgroundManager.skyState.weatherVariant,
            exposure:       backgroundManager.skyState.exposure
        }
        backgroundManager.commitSkyState(wFrom)
        wLerp = 0
    }

    Timer {
        id: demoAnim
        interval: 50; repeat: true; running: false
        property int tick: 0
        onTriggered: {
            tick++
            if (wLerp < wLerpDur) {
                wLerp++
                var t = wLerp / wLerpDur
                t = t * t * (3.0 - 2.0 * t)
                var interp = {}
                for (var key in wFrom)
                    interp[key] = wFrom[key] + (wTo[key] - wFrom[key]) * t
                backgroundManager.commitSkyState(interp)
            }
            demoHour += demoSpeed / 60
            if (demoHour >= 24) demoHour -= 24
            backgroundManager.setDebugTime(demoHour)
            var wi = demoSpeed > 0.5 ? 200 : 600
            if (tick % wi === 0) {
                var next = (demoWeatherIdx + 1) % demoWeatherList.length
                demoWeatherIdx = next
                switchWeather(demoWeatherList[next])
            }
        }
    }

    function startDemo() {
        if (demoMode) return
        demoMode = true
        dragging = true  // 面板透明
        demoHour = 0
        demoWeatherIdx = 0
        backgroundManager.enterDebugMode()
        backgroundManager.updateWeather(demoWeatherList[0], demoWeatherList[0] < 150)
        backgroundManager.setDebugTime(0)
        demoAnim.start()
    }

    function stopDemo() {
        if (!demoMode) return
        demoMode = false
        dragging = false
        demoAnim.stop()
        backgroundManager.exitDebugMode()
    }

    Shortcut {
        sequence: "Ctrl+Shift+B"
        onActivated: {
            panel.visible = !panel.visible
            if (panel.visible) {
                console.log("[DebugPanel] opened")
                if (backgroundManager.controlMode !== 1) backgroundManager.enterDebugMode()
            } else {
                console.log("[DebugPanel] closed")
                if (backgroundManager.controlMode === 1) backgroundManager.exitDebugMode()
            }
        }
    }

    // [Close button] / 关闭按钮
    Rectangle {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 4
        width: 24; height: 24; radius: 12; color: "#d44"
        Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 14 }
        MouseArea { anchors.fill: parent
            onClicked: { panel.visible = false; if (backgroundManager.controlMode === 1) backgroundManager.exitDebugMode() }
        }
    }

    Flickable {
        anchors.fill: parent; anchors.margins: 8; anchors.topMargin: 32
        contentHeight: contentCol.implicitHeight + 16; clip: true

        ColumnLayout {
            id: contentCol; width: parent.width - 8; spacing: 5

            Text { text: "☰ 调试面板"; font.pixelSize: 15; font.bold: true; color: "#333" }

            // === 模式 ===
            RowLayout { spacing: 8
                Text { text: "模式:"; color: "#555" }
                Button { text: "● Auto"; onClicked: { if (backgroundManager.controlMode === 1) backgroundManager.exitDebugMode() } }
                Button { text: "◉ Debug"; onClicked: { if (backgroundManager.controlMode === 0) backgroundManager.enterDebugMode() } }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === Layer 状态 ===
            Text { text: "Layer 状态"; font.bold: true; color: "#555" }
            GridLayout { columns: 3; columnSpacing: 8; rowSpacing: 2
                Repeater {
                    model: [
                        { label: "Sky",      active: true },
                        { label: "Cloud",    active: transitionCtrl.cloudActive, tp: transitionCtrl.cloudTP },
                        { label: "Weather",  active: transitionCtrl.weatherActive, tp: transitionCtrl.weatherTP },
                        { label: "Fog",      active: transitionCtrl.fogActive, tp: transitionCtrl.fogTP },
                        { label: "Lightning",active: transitionCtrl.lightningActive }
                    ]
                    delegate: Item { implicitWidth: 90; implicitHeight: 20
                        Rectangle { width: 10; height: 10; anchors.verticalCenter: parent.verticalCenter; radius: 5; color: modelData.active ? "#4a4" : "#aaa" }
                        Text { x: 16; anchors.verticalCenter: parent.verticalCenter
                            text: modelData.tp !== undefined && modelData.active ? modelData.label + " " + modelData.tp.toFixed(2) : modelData.label + (modelData.active ? " ●" : " ○")
                            font.pixelSize: 12; color: "#444"
                        }
                    }
                }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 过渡控制 ===
            Text { text: "过渡控制"; font.bold: true; color: "#555" }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "云 tp"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: tpCloud; Layout.fillWidth: true; from: 0; to: 1; stepSize: 0.01
                    value: transitionCtrl.debugCloudTP
                    enabled: transitionCtrl.cloudActive && backgroundManager.controlMode === 1 && !transitionCtrl.fadeInEnabled
                    onMoved: transitionCtrl.debugCloudTP = value
                }
                Text {
                    text: tpCloud.value <= 0.001 ? "自动" : tpCloud.value.toFixed(2)
                    width: 40; font.pixelSize: 11; color: "#888"
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "天气 tp"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: tpWeather; Layout.fillWidth: true; from: 0; to: 1; stepSize: 0.01
                    value: transitionCtrl.debugWeatherTP
                    enabled: transitionCtrl.weatherActive && backgroundManager.controlMode === 1 && !transitionCtrl.fadeInEnabled
                    onMoved: transitionCtrl.debugWeatherTP = value
                }
                Text {
                    text: tpWeather.value <= 0.001 ? "自动" : tpWeather.value.toFixed(2)
                    width: 40; font.pixelSize: 11; color: "#888"
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雾 tp"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: tpFog; Layout.fillWidth: true; from: 0; to: 1; stepSize: 0.01
                    value: transitionCtrl.debugFogTP
                    enabled: transitionCtrl.fogActive && backgroundManager.controlMode === 1 && !transitionCtrl.fadeInEnabled
                    onMoved: transitionCtrl.debugFogTP = value
                }
                Text {
                    text: tpFog.value <= 0.001 ? "自动" : tpFog.value.toFixed(2)
                    width: 40; font.pixelSize: 11; color: "#888"
                }
            }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "淡入"; width: 60; font.pixelSize: 11; color: "#555" }
                CheckBox {
                    id: chkFadeIn
                    checked: transitionCtrl.fadeInEnabled
                    enabled: backgroundManager.controlMode === 1
                    onClicked: transitionCtrl.fadeInEnabled = checked
                }
                Text { text: chkFadeIn.checked ? "渐变激活" : "即时激活"; font.pixelSize: 11; color: "#888" }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 时间控制 ===
            Text { text: "时间控制"; font.bold: true; color: "#555" }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "时间"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldTime; Layout.fillWidth: true; from: 0; to: 24; stepSize: 0.05
                    value: 12
                    enabled: backgroundManager.controlMode === 1
                    onMoved: backgroundManager.setDebugTime(value)
                }
                Text {
                    text: {
                        var h = Math.floor(sldTime.value)
                        var m = Math.round((sldTime.value - h) * 60)
                        if (m >= 60) { h += 1; m -= 60 }
                        return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m
                    }
                    width: 40; font.pixelSize: 11; color: "#888"
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "太阳高度"; width: 60; font.pixelSize: 11; color: "#555" }
                Text { text: backgroundManager.skyState.solarAltitude.toFixed(1) + "°"; font.pixelSize: 11; color: "#333" }
                Text {
                    text: {
                        var alt = backgroundManager.skyState.solarAltitude
                        if (alt > 5) return "白天"
                        if (alt > -5) return "黄昏/黎明"
                        return "夜晚"
                    }
                    font.pixelSize: 11; color: "#666"
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "本地时间"; width: 60; font.pixelSize: 11; color: "#555" }
                Text { text: backgroundManager.currentLocalTime; font.pixelSize: 11; color: "#333"; font.bold: true }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "时段"; width: 60; font.pixelSize: 11; color: "#555" }
                Text {
                    text: {
                        var a = backgroundManager.skyState.solarAltitude
                        if (a > 20) return "☀ 白天"
                        if (a > 8)  return "🌤 暖午后"
                        if (a > 4)  return "🌅 橙红"
                        if (a > 0)  return "🌄 金粉"
                        if (a > -5) return "🌆 紫调"
                        if (a > -12) return "🌇 蓝调"
                        return "🌙 深夜"
                    }
                    font.pixelSize: 11; color: "#333"; font.bold: true
                }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 天气码模拟 ===
            Text { text: "天气码模拟"; font.bold: true; color: "#555" }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "icon"; width: 60; font.pixelSize: 11; color: "#555" }
                TextField {
                    id: txtCode
                    text: "100"
                    Layout.fillWidth: true
                    validator: IntValidator { bottom: 100; top: 999 }
                    font.pixelSize: 11
                    enabled: backgroundManager.controlMode === 1
                }
                CheckBox {
                    id: chkIsDay
                    checked: true
                    text: "白天"
                    font.pixelSize: 11
                    enabled: backgroundManager.controlMode === 1
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "预设"; width: 60; font.pixelSize: 11; color: "#555" }
                ComboBox {
                    id: cbPreset
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    model: ["100-晴","101-多云","102-少云","103-晴间多云","104-阴",
                            "150-晴(夜)","151-多云(夜)","152-阴(夜)","153-晴间多云(夜)",
                            "300-阵雨","301-强阵雨","302-雷阵雨","303-强雷阵雨","304-雷阵雨伴冰雹",
                            "305-小雨","306-中雨","307-大雨","308-极端降雨","309-毛毛雨",
                            "310-暴雨","311-大暴雨","312-特大暴雨","313-冻雨",
                            "350-阵雨(夜)","351-强阵雨(夜)",
                            "399-雨(通用)",
                            "400-小雪","401-中雪","402-大雪","403-暴雪",
                            "404-雨夹雪","405-雨雪天气","406-阵雨夹雪","407-阵雪",
                            "456-阵雨夹雪(夜)","457-阵雪(夜)",
                            "499-雪(通用)",
                            "500-薄雾","501-雾","502-霾","503-扬沙","504-浮尘",
                            "507-沙尘暴","508-强沙尘暴"]
                    enabled: backgroundManager.controlMode === 1
                    onActivated: function(idx) {
                        var code = model[idx].split("-")[0]
                        txtCode.text = code
                        chkIsDay.checked = parseInt(code) < 150
                    }
                }
                Button {
                    text: "应用"
                    enabled: backgroundManager.controlMode === 1
                    onClicked: {
                        var code = parseInt(txtCode.text)
                        if (!isNaN(code)) {
                            backgroundManager.updateWeather(code, chkIsDay.checked)
                            console.log("[DebugPanel] updateWeather code=" + code + " isDay=" + chkIsDay.checked)
                        }
                    }
                }
            }

            RowLayout { Layout.fillWidth: true; spacing: 4; visible: backgroundManager.controlMode === 0
                Text { text: "当前"; width: 60; font.pixelSize: 11; color: "#555" }
                Text {
                    text: backgroundManager.currentWeatherCode + " "
                          + (backgroundManager.currentIsDay ? "☀白天" : "🌙夜间")
                    font.pixelSize: 11; color: "#333"; font.bold: true
                }
            }

            // === 天文 ===
            Text { text: "天文"; font.bold: true; color: "#555" }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "太阳高度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSA; Layout.fillWidth: true; from: -10; to: 90
                    value: backgroundManager.skyState.solarAltitude; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldSA.value.toFixed(1) + "°"; width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "太阳方位"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSZ; Layout.fillWidth: true; from: 0; to: 360
                    value: backgroundManager.skyState.solarAzimuth; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldSZ.value.toFixed(1) + "°"; width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "月亮高度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldMA; Layout.fillWidth: true; from: -90; to: 90
                    value: backgroundManager.skyState.moonAltitude; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldMA.value.toFixed(1) + "°"; width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "月亮方位"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldMZ; Layout.fillWidth: true; from: 0; to: 360
                    value: backgroundManager.skyState.moonAzimuth; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldMZ.value.toFixed(1) + "°"; width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "月相"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldMP; Layout.fillWidth: true; from: 0; to: 8
                    value: backgroundManager.skyState.moonPhase; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldMP.value.toFixed(1); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "月光"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldMI; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.moonIllum; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldMI.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 天气 ===
            Text { text: "天气"; font.bold: true; color: "#555" }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "云覆盖率"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldCC; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.cloudCoverage; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldCC.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雨强度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldRI; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.rainIntensity; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldRI.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雪强度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSI; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.snowIntensity; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldSI.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雾密度"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldFD; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.fogDensity; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldFD.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "闪电概率"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldLP; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.lightningProb; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldLP.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "星星"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldSV; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.starVisibility; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldSV.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "云变体"; width: 60; font.pixelSize: 11; color: "#555" }
                ComboBox {
                    id: cbCloudV
                    model: ["0-少云","1-多云","2-阴"]
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    enabled: backgroundManager.controlMode === 1
                    Component.onCompleted: currentIndex = backgroundManager.skyState.cloudVariant
                    onActivated: commit()
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雾变体"; width: 60; font.pixelSize: 11; color: "#555" }
                ComboBox {
                    id: cbFogV
                    model: ["0-雾","1-霾","2-沙尘"]
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    enabled: backgroundManager.controlMode === 1
                    Component.onCompleted: currentIndex = backgroundManager.skyState.fogVariant
                    onActivated: commit()
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "雨变体"; width: 60; font.pixelSize: 11; color: "#555" }
                ComboBox {
                    id: cbRainV
                    model: ["0-普通","1-雷暴","2-冰雹","3-雷暴+冰雹"]
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    enabled: backgroundManager.controlMode === 1
                    Component.onCompleted: currentIndex = backgroundManager.skyState.weatherVariant
                    onActivated: commit()
                }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "曝光"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldEX; Layout.fillWidth: true; from: 0.1; to: 2
                    value: backgroundManager.skyState.exposure; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldEX.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "黄昏因子"; width: 60; font.pixelSize: 11; color: "#555" }
                Slider { id: sldTF; Layout.fillWidth: true; from: 0; to: 1
                    value: backgroundManager.skyState.twilightFactor; enabled: backgroundManager.controlMode === 1; onMoved: commit()
    onPressedChanged: panel.dragging = pressed }
                Text { text: sldTF.value.toFixed(2); width: 50; font.pixelSize: 11; color: "#888" }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 配置持久化 ===
            RowLayout { Layout.fillWidth: true; spacing: 4
                Item { width: 60; height: 1 }
                Button {
                    text: "保存配置"
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    onClicked: backgroundManager.saveProfileForCode(parseInt(txtCode.text))
                }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 演示 ===
            RowLayout { Layout.fillWidth: true; spacing: 4
                Item { width: 60; height: 1 }
                Button {
                    text: demoMode ? "■ 停止" : "▶ 演示"
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    onClicked: demoMode ? stopDemo() : startDemo()
                }
                CheckBox {
                    id: chkFast
                    text: "快速"
                    checked: true
                    font.pixelSize: 11
                    onCheckedChanged: demoSpeed = checked ? 1.0 : 0.17
                }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 颜色 ===
            Text { text: "天空色"; font.bold: true; color: "#555" }

            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "天顶色"; width: 60; font.pixelSize: 11; color: "#555" }
                Rectangle { id: colorZenith; width: 60; height: 20; radius: 3; border.color: "#999"; border.width: 1
                    color: backgroundManager.skyState.zenithColor
                    enabled: backgroundManager.controlMode === 1
                    MouseArea { anchors.fill: parent; enabled: parent.enabled
                        onClicked: {
                            var pre = ["#4a90d9","#0a0a2e","#c05850","#3a5a8a","#1a2a5a"]
                            var idx = pre.indexOf(colorZenith.color.toString()) + 1
                            if (idx >= pre.length) idx = 0
                            colorZenith.color = pre[idx]; commit()
                        }
                    }
                }
                Text { text: colorZenith.color.toString().substr(1,6); font.pixelSize: 11; color: "#666" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "地平线色"; width: 60; font.pixelSize: 11; color: "#555" }
                Rectangle { id: colorHorizon; width: 60; height: 20; radius: 3; border.color: "#999"; border.width: 1
                    color: backgroundManager.skyState.horizonColor
                    enabled: backgroundManager.controlMode === 1
                    MouseArea { anchors.fill: parent; enabled: parent.enabled
                        onClicked: {
                            var pre = ["#87ceeb","#1a1a3e","#e89560","#d4996a","#4a3060"]
                            var idx = pre.indexOf(colorHorizon.color.toString()) + 1
                            if (idx >= pre.length) idx = 0
                            colorHorizon.color = pre[idx]; commit()
                        }
                    }
                }
                Text { text: colorHorizon.color.toString().substr(1,6); font.pixelSize: 11; color: "#666" }
            }
            RowLayout { Layout.fillWidth: true; spacing: 4
                Text { text: "环境色"; width: 60; font.pixelSize: 11; color: "#555" }
                Rectangle { id: colorAmbient; width: 60; height: 20; radius: 3; border.color: "#999"; border.width: 1
                    color: backgroundManager.skyState.ambientColor
                    enabled: backgroundManager.controlMode === 1
                    MouseArea { anchors.fill: parent; enabled: parent.enabled
                        onClicked: {
                            var pre = ["#c8e0f0","#15152e","#906050","#c0b0a0","#0a0a20"]
                            var idx = pre.indexOf(colorAmbient.color.toString()) + 1
                            if (idx >= pre.length) idx = 0
                            colorAmbient.color = pre[idx]; commit()
                        }
                    }
                }
                Text { text: colorAmbient.color.toString().substr(1,6); font.pixelSize: 11; color: "#666" }
            }

            Rectangle { height: 1; color: "#ccc"; Layout.fillWidth: true }

            // === 快捷操作 ===
            Text { text: "快捷操作"; font.bold: true; color: "#555" }
            RowLayout { spacing: 4
                Button { text: "晴天"; onClicked: { setQVals({solarAltitude:60,cloudCoverage:0,rainIntensity:0,snowIntensity:0,fogDensity:0,starVisibility:0,lightningProb:0,twilightFactor:0}); commit() } }
                Button { text: "多云"; onClicked: { setQVals({solarAltitude:45,cloudCoverage:0.6,starVisibility:0}); commit() } }
                Button { text: "下雨"; onClicked: { setQVals({cloudCoverage:0.8,rainIntensity:0.6,snowIntensity:0,fogDensity:0,starVisibility:0,twilightFactor:0}); commit() } }
                Button { text: "夜晚"; onClicked: { setQVals({solarAltitude:-20,starVisibility:0.8,cloudCoverage:0,rainIntensity:0,snowIntensity:0,fogDensity:0}); commit() } }
            }

            Button { text: "📋 转储状态"; Layout.fillWidth: true
                onClicked: { console.log(backgroundManager.dumpState()); console.log(transitionCtrl.dumpState()) }
            }
        }
    }

    // 设滑块值（快捷操作用）
    function setQVals(v) {
        if (v.solarAltitude  !== undefined) sldSA.value = v.solarAltitude
        if (v.solarAzimuth   !== undefined) sldSZ.value = v.solarAzimuth
        if (v.moonAltitude   !== undefined) sldMA.value = v.moonAltitude
        if (v.moonAzimuth    !== undefined) sldMZ.value = v.moonAzimuth
        if (v.moonPhase      !== undefined) sldMP.value = v.moonPhase
        if (v.moonIllum      !== undefined) sldMI.value = v.moonIllum
        if (v.cloudCoverage  !== undefined) sldCC.value = v.cloudCoverage
        if (v.rainIntensity  !== undefined) sldRI.value = v.rainIntensity
        if (v.snowIntensity  !== undefined) sldSI.value = v.snowIntensity
        if (v.fogDensity     !== undefined) sldFD.value = v.fogDensity
        if (v.lightningProb  !== undefined) sldLP.value = v.lightningProb
        if (v.starVisibility !== undefined) sldSV.value = v.starVisibility
        if (v.cloudVariant   !== undefined) cbCloudV.currentIndex = v.cloudVariant
        if (v.fogVariant     !== undefined) cbFogV.currentIndex = v.fogVariant
        if (v.weatherVariant !== undefined) cbRainV.currentIndex = v.weatherVariant
        if (v.exposure       !== undefined) sldEX.value = v.exposure
        if (v.twilightFactor !== undefined) sldTF.value = v.twilightFactor
    }

    Component.onCompleted: { console.log("[DebugPanel] ready — Ctrl+Shift+B to toggle") }

    // 从 backend 同步 variant 状态
    Connections {
        target: backgroundManager
        function onSkyStateChanged() {
            cbCloudV.currentIndex = backgroundManager.skyState.cloudVariant
            cbFogV.currentIndex = backgroundManager.skyState.fogVariant
            cbRainV.currentIndex = backgroundManager.skyState.weatherVariant
        }
    }
}
