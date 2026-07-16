import QtQuick

// 城市信息卡片 —— 半透明圆角矩形，显示城市名 + 天气图标 + 温度
// 单击切换焦点，双击跳转详情，hover 半透明高亮
Rectangle {
    id: card
    width: 160; height: 100
    radius: 12
    color: hoverArea.containsMouse ? "#25ffffff" : "#20ffffff"
    border.width: 1
    border.color: hoverArea.containsMouse ? "#50ffffff" : "#30ffffff"

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    property string cityName: ""
    property string cityId: ""
    property bool isFocus: false
    property var weatherData: ({})
    signal clicked(string cityId)
    signal doubleClicked(string cityId)
    signal closeClicked(string cityId)

    // 顶部叉号 — hover 时显示
    Rectangle {
        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 4
        width: 18; height: 18; radius: 9
        z: 1
        color: hoverArea.containsMouse ? "#44ffffff" : "transparent"
        opacity: hoverArea.containsMouse ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: "\u00d7"; color: "white"; font.pixelSize: 12; font.bold: true
        }
        MouseArea {
            anchors.fill: parent
            onClicked: {
                clickTimer.stop()
                card.closeClicked(card.cityId)
            }
        }
    }

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
            iconSize: Math.max(22, Math.min(36, card.height * 0.35))
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.cityName || "--"
            color: "white"
            font.pixelSize: Math.max(12, Math.min(16, card.width * 0.09))
            font.bold: card.isFocus
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.weatherData.temp ? card.weatherData.temp + "°" : "--°"
            color: "white"
            font.pixelSize: Math.max(18, Math.min(28, card.height * 0.22))
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
