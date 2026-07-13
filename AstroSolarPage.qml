import QtQuick
import QtQuick.Layouts

// 阳光天文页 —— 2×2 卡片，显示日出日落 + 月相
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
            delegate: Rectangle {
                width: 200; height: 120
                radius: 12
                color: "#20000000"
                border.width: 1; border.color: "#30ffffff"

                property var astro: page.store ? (page.store.cityWeather[modelData.id] || {}).astro || {} : {}

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        color: "white"; font.pixelSize: 14
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "日出 " + (parent.parent.astro.sunrise || "--")
                        color: "#ccffffff"; font.pixelSize: 12
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "日落 " + (parent.parent.astro.sunset || "--")
                        color: "#ccffffff"; font.pixelSize: 12
                    }
                }
            }
        }
    }
}
