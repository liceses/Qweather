// ForecastPage.qml — Forecast page with range selector and 2×2 card grid
// 天气预报页 — 范围选择器 + 2×2 卡片网格，数据由 C++ forecastStore 驱动
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: page

    // [EN] Current forecast mode (hourly/daily) / [CN] 当前预报模式（逐小时/逐日）
    readonly property string mode: forecastStore ? forecastStore.mode : "daily"

    // [EN] Available forecast ranges / [CN] 可选预报范围
    readonly property var ranges: ["24h", "72h", "168h", "3d", "7d", "10d", "15d", "30d"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(8, Math.min(page.width, page.height) * 0.025)
        spacing: Math.max(4, Math.min(page.height, page.width) * 0.012)

        // [EN] Range selector row / [CN] 预报范围选择行
        Row {
            id: selectorRow
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(28, page.height * 0.05)
            spacing: Math.max(3, page.width * 0.004)
            Layout.alignment: Qt.AlignHCenter

            Repeater {
                model: page.ranges

                Loader {
                    active: modelData === "3d"
                    visible: active
                    sourceComponent: Rectangle {
                        width: 1; height: selectorRow.height * 0.5
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        color: "#30ffffff"
                    }
                }

                Rectangle {
                    id: btn
                    readonly property string r: modelData
                    readonly property bool active: forecastStore && forecastStore.range === r
                    radius: Math.max(3, page.height * 0.006)
                    color: btnMouse.containsMouse ? "#25c0c0c0"
                           : active ? "#334caf50" : "transparent"
                    border.width: active ? 1 : 0
                    border.color: active ? "#604caf50" : "transparent"
                    width: Math.max(lbl.implicitWidth + Math.max(8, page.width * 0.012),
                                    Math.max(32, page.width * 0.035))
                    height: selectorRow.height

                    Text {
                        id: lbl
                        anchors.centerIn: parent
                        text: r.indexOf("h") >= 0 ? r.replace("h", "小时") : r.replace("d", "天")
                        color: btn.active ? "#ffffff" : "#80ffffff"
                        font.pixelSize: Math.max(10, Math.min(14, page.width * 0.013))
                    }
                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { if (forecastStore) forecastStore.range = modelData }
                    }
                }
            }
        }

        // [EN] 2×2 forecast card grid / [CN] 2×2 预报卡片网格
        Grid {
            id: cardGrid
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 2
            spacing: Math.max(6, Math.min(page.width, page.height) * 0.012)

            Repeater {
                model: forecastStore ? forecastStore.cities.slice(0, 4) : []

                ForecastCard {
                    width: Math.max(180, (cardGrid.width - cardGrid.spacing) / 2)
                    height: Math.max(140, (cardGrid.height - cardGrid.spacing) / 2)
                    cityId: modelData.id || ""
                    cityName: modelData.name || ""
                    mode: page.mode
                }
            }
        }
    }
}
