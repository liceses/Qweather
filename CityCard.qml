// CityCard.qml — City info card with weather icon, name, temp; click/double-click/close
// 城市信息卡片 — 半透明圆角卡片，显示城市名 + 天气图标 + 温度，支持单击/双击/关闭
import QtQuick

Rectangle {
    id: card
    width: 160; height: 100
    radius: 12
    color: hoverArea.containsMouse ? "#25ffffff" : "#20ffffff"
    border.width: 1
    border.color: hoverArea.containsMouse ? "#50ffffff" : "#30ffffff"

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // [EN] City display name, ID, focus state, weather data / [CN] 城市显示名、ID、焦点状态、天气数据
    property string cityName: ""
    property string cityId: ""
    property bool isFocus: false
    property var weatherData: ({})
    // [EN] Signals: single click, double click, close / [CN] 单击、双击、关闭信号
    signal clicked(string cityId)
    signal doubleClicked(string cityId)
    signal closeClicked(string cityId)

    // [EN] Close button — visible on hover / [CN] 顶部关闭按钮 — 悬停时显示
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

    // [EN] Focus highlight overlay / [CN] 焦点城市高亮覆盖层
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: card.isFocus ? "#404caf50" : "transparent"
    }

    // [EN] Content: weather icon, city name, temperature / [CN] 内容：天气图标、城市名、温度
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

    // [EN] Double-click detection: wait 400ms to distinguish click vs double-click / [CN] 双击检测：400ms 内判定双击，超时判单击
    property var _lastClickTime: 0
    Timer {
        id: clickTimer
        interval: 400
        onTriggered: {
            card.clicked(card.cityId)
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
                card.doubleClicked(card.cityId)
            } else {
                card._lastClickTime = now
                clickTimer.restart()
            }
        }
    }
}
