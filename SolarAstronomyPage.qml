// SolarAstronomyPage.qml — Solar / astronomy page with 2×2 card grid
// 阳光天文页 — 2×2 卡片网格，数据由 C++ solarAstronomyStore 驱动
import QtQuick
import QtQuick.Layouts

Item {
    id: page

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Math.max(8, Math.min(page.width, page.height) * 0.025)
        spacing: Math.max(6, Math.min(page.height, page.width) * 0.012)

        // [EN] Page title (toggles between Solar+Astronomy or just Astronomy) / [CN] 页面标题（切换太阳辐射模式时显示不同名称）
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: appSettings && appSettings.showSolarRadiation ? "阳光天文" : "朝夕月相"
            color: "white"
            font.pixelSize: Math.max(16, Math.min(26, page.width * 0.025))
            font.bold: true
        }

        // [EN] 2×2 solar/astronomy card grid / [CN] 2×2 阳光天文卡片网格
        Grid {
            id: cardGrid
            Layout.fillWidth: true; Layout.fillHeight: true
            columns: 2
            spacing: Math.max(8, Math.min(page.width, page.height) * 0.015)

            Repeater {
                model: solarAstronomyStore ? solarAstronomyStore.cities.slice(0, 4) : []

                SolarAstronomyCard {
                    width: Math.max(200, (cardGrid.width - cardGrid.spacing) / 2)
                    height: Math.max(200, (cardGrid.height - cardGrid.spacing) / 2)
                    cityId: modelData.id || ""
                    cityName: modelData.name || ""
                    solarData: solarAstronomyStore ? (solarAstronomyStore.solarData[modelData.id] || ({})) : ({})
                    showSolarRadiation: appSettings ? appSettings.showSolarRadiation : true
                }
            }
        }
    }
}
