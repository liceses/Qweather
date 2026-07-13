import QtQuick
import QtQuick.Layouts

// 空气质量页 —— 2×2 卡片布局，显示 AQI + 首要污染物
Item {
    id: page
    property var store: null
    property var weatherApi: null

    Grid {
        anchors.centerIn: parent
        columns: 2
        spacing: 16

        Repeater {
            model: page.store ? page.store.trackedCities.slice(0, 4) : []

            Rectangle {
                width: 200; height: 120
                radius: 12
                color: "#20000000"
                border.width: 1
                border.color: "#30ffffff"

                property var aqiData: page.store ? (page.store.cityWeather[modelData.id] || {}) : ({})

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        color: "white"
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.parent.aqiData.aqi || "--"
                        color: "white"
                        font.pixelSize: 32
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.parent.aqiData.category || "暂无数据"
                        color: "#ccffffff"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
