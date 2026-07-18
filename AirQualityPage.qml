// AirQualityPage.qml — Air quality page with 2×2 card grid
// 空气质量页 — 2×2 卡片网格，数据由 C++ airQualityStore 驱动
import QtQuick
import QtQuick.Layouts

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(8, Math.min(page.width, page.height) * 0.025)
        spacing: Math.max(6, Math.min(page.height, page.width) * 0.012)

        // [EN] Page title / [CN] 页面标题
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "空气质量"
            color: "white"
            font.pixelSize: Math.max(16, Math.min(26, page.width * 0.025))
            font.bold: true
        }

        // [EN] 2×2 air quality card grid / [CN] 2×2 空气质量卡片网格
        Grid {
            id: cardGrid
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 2
            spacing: Math.max(8, Math.min(page.width, page.height) * 0.015)

            Repeater {
                model: airQualityStore ? airQualityStore.cities.slice(0, 4) : []

                AirQualityCard {
                    width: Math.max(200, (cardGrid.width - cardGrid.spacing) / 2)
                    height: Math.max(200, (cardGrid.height - cardGrid.spacing) / 2)
                    cityId: modelData.id || ""
                    cityName: modelData.name || ""
                    airData: airQualityStore ? (airQualityStore.airData[modelData.id] || ({})) : ({})
                }
            }
        }
    }
}
