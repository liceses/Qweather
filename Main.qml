import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    visible: true
    title: "天气"

    // ===== 全局数据单例 =====
    CityStore { id: store }

    property var focusWeather: ({})
    property alias focusCityId: store.focusCityId
    property alias focusCityName: sidePanel.focusCityName

    // ===== 初始化 =====
    Component.onCompleted: {
        weatherApi.topCity("cn", 4)
    }

    // ===== Layer 0: 背景 =====
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#4a90d9" }
            GradientStop { position: 1.0; color: "#87ceeb" }
        }
    }

    // ===== Layer 1: 主布局 =====
    RowLayout {
        anchors.fill: parent
        spacing: 0

        SidePanel {
            id: sidePanel
            Layout.preferredWidth: sidePanel.expanded ? 200 : 80
            Layout.fillHeight: true
            currentPage: mainStack.currentIndex
            focusCityName: store.pinnedCityId ? store.cityName(store.pinnedCityId)
                                               : (store.focusCityId ? store.cityName(store.focusCityId) : "北京")
            onPageChanged: function(page) { mainStack.currentIndex = page }
        }

        StackLayout {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // ===== Page 0: 仪表盘 =====
            DashboardPage { id: dashPage; store: store; weatherApi: weatherApi }

            // ===== Page 1: 空气质量 =====
            AirQualityPage { store: store; weatherApi: weatherApi }

            // ===== Page 2: 天气预报 =====
            ForecastPage { id: forecastPage; store: store; weatherApi: weatherApi }

            // ===== Page 3: 阳光天文 =====
            AstroSolarPage { store: store; weatherApi: weatherApi }

            // ===== Page 4: 城市详情 =====
            CityDetailPage {
                store: store; weatherApi: weatherApi
                cityId: store.pinnedCityId || store.focusCityId
            }

            // ===== Page 5: 收藏 =====
            FavoritesPage { store: store }

            // ===== Page 6: 设置 =====
            SettingsPage { id: settingsPage; weatherCache: null }
        }
    }

    // ===== 全局信号转发 =====
    Connections {
        target: weatherApi
        function onCityTopReady(cities) {
            for (let i = 0; i < Math.min(cities.length, 4); i++) {
                let c = cities[i]
                store.addCity({ name: c.name, id: c.id, lat: c.lat, lon: c.lon })
                weatherApi.weatherNow(c.id)
            }
            if (!store.focusCityId && store.trackedCities.length > 0) {
                store.focusCityId = store.trackedCities[0].id
            }
        }
        function onWeatherNowReady(now) {
            store.updateWeather(now._location, now.temp, now.icon, now.text)
        }
        function onWeatherDailyReady(loc, daily) {
            store.updateDaily(loc, daily)
        }
    }
}
