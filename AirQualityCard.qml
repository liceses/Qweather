// AirQualityCard.qml — Air quality display card with AQI, category, pollutant grid
// 空气质量卡片 — AQI 指数、类别、污染物网格展示
import QtQuick
import QtQuick.Layouts

Item {
    id: card

    // [EN] City ID, display name, air quality data / [CN] 城市 ID、显示名、空气质量数据
    property string cityId: ""
    property string cityName: ""
    property var airData: ({})

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
            anchors.margins: Math.max(6, Math.min(card.width, card.height) * 0.04)
            spacing: Math.max(2, card.height * 0.01)

            // [EN] City name / [CN] 城市名
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.cityName || "--"
                color: "white"
                font.pixelSize: Math.max(13, Math.min(20, card.width * 0.065))
                font.bold: true
                elide: Text.ElideRight
                Layout.maximumWidth: card.width * 0.85
            }

            // [EN] AQI value with color dot / [CN] AQI 大数字 + 彩色圆点
            Row {
                Layout.alignment: Qt.AlignHCenter
                spacing: Math.max(4, card.width * 0.015)

                Rectangle {
                    width: aqiText.height * 0.45
                    height: aqiText.height * 0.45
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: card.airData.color || "#888"
                }

                Text {
                    id: aqiText
                    text: card.airData.aqi || "--"
                    color: "white"
                    font.pixelSize: Math.max(28, Math.min(48, card.height * 0.18))
                    font.bold: true
                }
            }

            // [EN] Air quality category / [CN] 空气质量类别
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.airData.category || ""
                color: card.airData.color || "#80ffffff"
                font.pixelSize: Math.max(11, Math.min(18, card.width * 0.055))
                font.bold: true
            }

            // [EN] Primary pollutant / [CN] 首要污染物
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: card.airData.primaryPollutant ? "首要: " + card.airData.primaryPollutant : ""
                color: "#aaffffff"
                font.pixelSize: Math.max(9, Math.min(13, card.width * 0.042))
                visible: text !== ""
            }

            // [EN] Pollutant data grid / [CN] 污染物数据网格
            Grid {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                columns: 2
                spacing: Math.max(2, card.height * 0.005)
                visible: !!card.airData.pollutants && card.airData.pollutants.length > 0

                Repeater {
                    model: card.airData.pollutants || []

                    Rectangle {
                        width: Math.max(70, (parent ? parent.width : 100) / 2 - 2)
                        height: Math.max(18, card.height * 0.08)
                        radius: 4
                        color: "#15ffffff"
                        border.width: 1; border.color: "#20ffffff"

                        Row {
                            anchors.centerIn: parent
                            spacing: 3

                            Text {
                                text: modelData.name || ""
                                color: "#ccffffff"
                                font.pixelSize: Math.max(7, Math.min(10, card.height * 0.035))
                            }
                            Text {
                                text: (modelData.value !== undefined ? modelData.value : "--") + " " + (modelData.unit || "")
                                color: "#ffffff"
                                font.pixelSize: Math.max(7, Math.min(10, card.height * 0.035))
                                font.bold: true
                            }
                        }
                    }
                }
            }

            // [EN] No-data placeholder / [CN] 无数据占位提示
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "暂无空气质量数据"
                color: "#60ffffff"
                font.pixelSize: Math.max(10, Math.min(16, card.width * 0.05))
                visible: !card.airData.aqi
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
    }
}
