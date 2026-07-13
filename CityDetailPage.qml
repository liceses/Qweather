import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 城市详情页 —— TabBar 切换多维度数据
Item {
    id: page
    property var store: null
    property var weatherApi: null
    property string cityId: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12

        // 城市名
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: page.store ? page.store.cityName(page.cityId) : ""
            color: "white"
            font.pixelSize: 36
            font.bold: true
        }

        // 天气摘要
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            WeatherIcon {
                code: (page.store && page.store.cityWeather[page.cityId])
                      ? page.store.cityWeather[page.cityId].icon || "100" : "100"
                iconSize: 36
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: (page.store && page.store.cityWeather[page.cityId])
                      ? (page.store.cityWeather[page.cityId].temp || "--") + "°" : "--°"
                color: "white"; font.pixelSize: 42; font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: (page.store && page.store.cityWeather[page.cityId])
                      ? page.store.cityWeather[page.cityId].text || "" : ""
                color: "#ccffffff"; font.pixelSize: 24
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // TabBar
        TabBar {
            id: tabBar
            Layout.alignment: Qt.AlignHCenter
            TabButton { text: "实时" }
            TabButton { text: "逐日" }
            TabButton { text: "逐时" }
            TabButton { text: "天文" }
        }

        // 内容区
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // 实时天气
            Item {
                Row {
                    anchors.centerIn: parent; spacing: 20
                    InfoChip { label: "体感"; value: weatherValue("feelsLike") }
                    InfoChip { label: "湿度"; value: weatherValue("humidity") + "%" }
                    InfoChip { label: "气压"; value: weatherValue("pressure") }
                    InfoChip { label: "能见度"; value: weatherValue("vis") + "km" }
                }
            }

            // 逐日预报
            ListView {
                anchors.fill: parent
                model: page.store ? (page.store.cityWeather[page.cityId] || {}).daily || [] : []
                delegate: ItemDelegate {
                    width: parent.width; height: 40
                    Text {
                        anchors.centerIn: parent
                        color: "white"
                        text: modelData.fxDate + "  " + modelData.textDay + " " + modelData.tempMax + "/" + modelData.tempMin + "°"
                    }
                }
            }

            // 逐小时预报
            ListView {
                anchors.fill: parent
                model: page.store ? (page.store.cityWeather[page.cityId] || {}).hourly || [] : []
                delegate: ItemDelegate {
                    width: parent.width; height: 36
                    Text {
                        anchors.centerIn: parent
                        color: "white"; font.pixelSize: 12
                        text: modelData.fxTime + "  " + modelData.temp + "°  " + (modelData.text || "")
                    }
                }
            }

            // 天文
            Item {
                Column {
                    anchors.centerIn: parent; spacing: 8
                    Text { color: "white"; text: "日出: " + weatherValue("sunrise"); font.pixelSize: 16 }
                    Text { color: "white"; text: "日落: " + weatherValue("sunset"); font.pixelSize: 16 }
                }
            }
        }
    }

    function weatherValue(key) {
        if (!page.store) return "--"
        let w = page.store.cityWeather[page.cityId]
        return w ? (w[key] || "--") : "--"
    }
}
