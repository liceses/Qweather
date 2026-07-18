// ForecastCard.qml — Individual forecast card with chart (hourly/daily)
// 预报卡片 — 含折线图（逐小时/逐日），数据由 C++ forecastStore 驱动
import QtQuick
import QtQuick.Layouts
import QtCharts

Item {
    id: card

    // [EN] City ID, display name, chart mode (hourly/daily) / [CN] 城市 ID、显示名、图表模式（逐小时/逐日）
    property string cityId: ""
    property string cityName: ""
    property string mode: "hourly"

    // [EN] Chart data points from forecastStore / [CN] 从 forecastStore 获取图表数据点
    property var points: {
        if (!forecastStore || !forecastStore.chartData) return []
        var d = forecastStore.chartData[cityId + "_" + mode]
        return d !== undefined ? d : []
    }
    // [EN] Extra info (weather text, icon) / [CN] 额外信息（天气描述、图标）
    property var info: {
        if (!forecastStore || !forecastStore.chartData) return ({})
        return forecastStore.chartData[cityId + "_info"] || ({})
    }

    // [EN] Card background with hover effect / [CN] 卡片背景，悬停时高亮
    Rectangle {
        anchors.fill: parent
        radius: Math.min(card.width, card.height) * 0.04
        color: cardMouse.containsMouse ? "#25ffffff" : "#20ffffff"
        border.width: 1
        border.color: cardMouse.containsMouse ? "#50ffffff" : "#30ffffff"
        clip: true

        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.max(4, Math.min(card.width, card.height) * 0.035)
            spacing: 0

            // [EN] Header: weather icon, city name, weather text / [CN] 头部：天气图标、城市名、天气描述
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.max(2, card.width * 0.01)
                WeatherIcon {
                    iconSize: Math.max(16, Math.min(28, card.height * 0.09))
                    code: mode === "hourly" ? (card.info.icon || "") : (card.info.iconDay || "")
                    isDay: true
                }
                Text {
                    text: card.cityName || "--"
                    color: "white"; font.bold: true
                    font.pixelSize: Math.max(11, Math.min(18, card.width * 0.06))
                    elide: Text.ElideRight
                    Layout.maximumWidth: card.width * 0.4
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: mode === "hourly" ? (card.info.text || "--") : (card.info.textDay || "--")
                    color: "#ccffffff"
                    font.pixelSize: Math.max(9, Math.min(13, card.width * 0.045))
                    elide: Text.ElideRight
                    Layout.maximumWidth: card.width * 0.3
                }
            }

            // [EN] Temperature trend chart / [CN] 温度趋势折线图
            ChartView {
                id: chartView
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.topMargin: Math.max(2, card.height * 0.01)
                antialiasing: true
                backgroundColor: "transparent"
                plotAreaColor: "transparent"
                legend.visible: true
                legend.labelColor: "#ccffffff"
                legend.font.pixelSize: Math.max(7, Math.min(11, card.height * 0.04))
                legend.alignment: Qt.AlignBottom

                ValueAxis {
                    id: axisX
                    labelsColor: "#aaffffff"; gridLineColor: "#15ffffff"
                    labelsFont.pixelSize: Math.max(6, Math.min(9, card.height * 0.03))
                    labelFormat: "%.0f"
                }
                ValueAxis {
                    id: axisY
                    labelsColor: "#aaffffff"; gridLineColor: "#15ffffff"
                    labelsFont.pixelSize: Math.max(6, Math.min(9, card.height * 0.03))
                    labelFormat: "%.0f"
                }

                // [EN] Pre-declare three series to avoid NaN axis issues on clear/append / [CN] 预声明三个 series，避免动态增删导致的 NaN 轴问题
                SplineSeries {
                    id: hourlySeries
                    name: "温度"; color: "#ff9800"
                    axisX: axisX; axisY: axisY
                }
                LineSeries {
                    id: maxSeries
                    name: "最高温"; color: "#ff5252"
                    axisX: axisX; axisY: axisY
                }
                LineSeries {
                    id: minSeries
                    name: "最低温"; color: "#448aff"
                    axisX: axisX; axisY: axisY
                }

                // [EN] No-data placeholder / [CN] 无数据占位提示
                Text {
                    anchors.centerIn: parent
                    text: "暂无预报数据"
                    color: "#60ffffff"
                    font.pixelSize: Math.max(10, Math.min(16, card.width * 0.05))
                    visible: !card.points || card.points.length === 0
                }
            }
        }
    }

    // [EN] Re-render chart when data or mode changes / [CN] 数据或模式变更时重新绘制图表
    onPointsChanged: updateChart()
    onModeChanged:  updateChart()

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // [EN] Render chart: compute axis range, append data points / [CN] 绘制图表：计算轴范围，追加数据点
    function updateChart() {
        if (!points || points.length === 0) {
            hourlySeries.clear(); maxSeries.clear(); minSeries.clear()
            hourlySeries.visible = false
            maxSeries.visible = false; minSeries.visible = false
            return
        }

        var n = points.length
        // [EN] Compute range → set axis → clear → append (axis won't auto-rescale after clear) / [CN] 先算数据范围 → 设轴 → clear → append（clear 后轴不自动重新缩放）
        var yMin = 99, yMax = -99
        for (var k = 0; k < n; k++) {
            if (mode === "hourly") {
                if (points[k].y < yMin) yMin = points[k].y
                if (points[k].y > yMax) yMax = points[k].y
            } else {
                if (points[k].yMin < yMin) yMin = points[k].yMin
                if (points[k].yMax > yMax) yMax = points[k].yMax
            }
        }
        var pad = Math.max(2, (yMax - yMin) * 0.1)
        axisX.min = 0; axisX.max = n - 1
        axisY.min = yMin - pad; axisY.max = yMax + pad
        axisX.tickCount = n <= 24 ? 6 : (n <= 72 ? 9 : n <= 168 ? 8 : Math.min(n, 10))

        hourlySeries.clear(); maxSeries.clear(); minSeries.clear()

        var lineW = Math.max(1, Math.min(3, card.height * 0.006))

        if (mode === "hourly") {
            hourlySeries.visible = true
            maxSeries.visible = false; minSeries.visible = false
            hourlySeries.width = lineW
            for (var i = 0; i < n; i++)
                hourlySeries.append(i, points[i].y)
        } else {
            hourlySeries.visible = false
            maxSeries.visible = true; minSeries.visible = true
            maxSeries.width = lineW; minSeries.width = lineW
            for (var j = 0; j < n; j++) {
                maxSeries.append(j, points[j].yMax)
                minSeries.append(j, points[j].yMin)
            }
        }
    }
}
