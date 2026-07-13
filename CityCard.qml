import QtQuick

// 城市信息卡片 —— 半透明圆角矩形，显示城市名 + 天气图标 + 温度
// 用法：CityCard { cityName:"北京"; cityId:"101010100"; isFocus:true; onClicked:{...} }
// 双击卡片 → 跳转 CityDetailPage（阶段 2 实现）

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
