import QtQuick

// 城市信息卡片 —— 半透明圆角矩形，显示城市名 + 天气图标 + 温度
// 单击切换焦点，双击跳转详情，hover 半透明高亮
Rectangle {
    id: card
    width: 160; height: 100
    radius: 12
    color: hoverArea.containsMouse ? "#35000000" : "#20000000"
    border.width: 1
    border.color: hoverArea.containsMouse ? "#50ffffff" : "#30ffffff"

    property string cityName: ""
    property string cityId: ""
    property bool isFocus: false
    property var weatherData: ({})
    signal clicked(string cityId)
    signal doubleClicked(string cityId)

    // 焦点高亮
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: card.isFocus ? "#404caf50" : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        WeatherIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            code: card.weatherData.icon || "100"
            iconSize: 32
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.cityName || "--"
            color: "white"
            font.pixelSize: 14
            font.bold: card.isFocus
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.weatherData.temp ? card.weatherData.temp + "°" : "--°"
            color: "white"
            font.pixelSize: 20
            font.bold: true
        }
    }

    // 双击检测
    property var _lastClickTime: 0
    Timer {
        id: clickTimer
        interval: 400
        onTriggered: {
            card.clicked(card.cityId)          // 超时 = 单击
            card._lastClickTime = 0
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            var now = Date.now()
            if (now - card._lastClickTime < 400) {
                clickTimer.stop()
                card._lastClickTime = 0
                card.doubleClicked(card.cityId)  // 双击
            } else {
                card._lastClickTime = now
                clickTimer.restart()             // 等 400ms 判单击
            }
        }
    }
}
