import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 设置页
Item {
    id: page
    property var weatherCache: null    // 外部注入 WeatherCache 实例

    ColumnLayout {
        anchors.centerIn: parent
        width: 400
        spacing: 16

        Text { text: "设置"; color: "white"; font.pixelSize: 24; Layout.alignment: Qt.AlignHCenter }

        // 缓存管理
        Rectangle {
            Layout.fillWidth: true; height: 48; radius: 8; color: "#20000000"
            RowLayout {
                anchors.fill: parent; anchors.margins: 12
                Text { text: "清除天气缓存"; color: "white"; font.pixelSize: 14; Layout.fillWidth: true }
                Button {
                    text: "清除"
                    onClicked: { if (page.weatherCache) page.weatherCache.clearAll() }
                }
            }
        }

        // 关于
        Rectangle {
            Layout.fillWidth: true; height: 48; radius: 8; color: "#20000000"
            RowLayout {
                anchors.fill: parent; anchors.margins: 12
                Text { text: "版本"; color: "white"; font.pixelSize: 14; Layout.fillWidth: true }
                Text { text: "v0.1"; color: "#80ffffff"; font.pixelSize: 14 }
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "数据来源：和风天气"
            color: "#60ffffff"; font.pixelSize: 11
        }
    }
}
