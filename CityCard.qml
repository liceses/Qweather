import QtQuick

Rectangle {
    id: card
    width: 160; height: 100
    radius: 12
    color: "#20000000"
    border.width: 1
    border.color: "#30ffffff"

    // 外部传入
    property string cityName: ""
    property string cityId: ""
    property bool isFocus: false
    property var weatherData: ({})      // { temp, icon, text }
    signal clicked(string cityId)

    // 焦点高亮
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: card.isFocus ? "#40ffffff" : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        // 图标
        WeatherIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            code: card.weatherData.icon || "100"
            iconSize: 32
        }

        // 城市名
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.cityName || "--"
            color: "white"
            font.pixelSize: 14
            font.bold: card.isFocus
        }

        // 温度
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.weatherData.temp ? card.weatherData.temp + "°" : "--°"
            color: "white"
            font.pixelSize: 20
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: card.clicked(card.cityId)
    }
}
