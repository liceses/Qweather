import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// 天气预报页 —— 天数选择器 + 2×2 卡片
Item {
    id: page
    property var store: null
    property var weatherApi: null
    property string days: "3d"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40

        // 天数选择器
        Row {
            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
            spacing: 8
            Repeater {
                model: ["3d", "7d", "10d"]
                Rectangle {
                    width: label.width + 20; height: 32; radius: 4
                    color: page.days === modelData ? "#334caf50" : "transparent"
                    Text {
                        id: label
                        anchors.centerIn: parent
                        text: modelData.replace("d", "天")
                        color: page.days === modelData ? "white" : "#80ffffff"
                        font.pixelSize: 13
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { page.days = modelData; page.refreshAll() }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Grid {
            Layout.alignment: Qt.AlignHCenter
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

                    property var daily: page.store ? (page.store.cityWeather[modelData.id] || {}).daily || [] : []

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
                            text: parent.parent.daily.length > 0
                                  ? parent.parent.daily[0].fxDate : "--"
                            color: "#ccffffff"
                            font.pixelSize: 11
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: parent.parent.daily.length > 0
                                  ? parent.parent.daily[0].textDay + " " + parent.parent.daily[0].tempMax + "/" + parent.parent.daily[0].tempMin + "°"
                                  : "暂无预报"
                            color: "white"
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }

    function refreshAll() {
        if (!page.weatherApi || !page.store) return
        for (let i = 0; i < Math.min(page.store.trackedCities.length, 4); i++) {
            page.weatherApi.weatherDaily(page.days, page.store.trackedCities[i].id)
        }
    }
}
