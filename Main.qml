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
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40

                    SearchBar {
                        id: searchBox
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        onCitySelected: function(cityId) {
                            root.switchFocus(cityId)
                        }
                    }

                    Item { Layout.preferredHeight: 40 }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: store.cityName(store.focusCityId) || "搜索城市开始"
                        color: "white"
                        font.pixelSize: 56
                        font.bold: true
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        WeatherIcon {
                            code: root.focusWeather.icon || "100"
                            iconSize: 42
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.focusWeather.text || "--"
                            color: "white"
                            font.pixelSize: 28
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: root.focusWeather.temp ? root.focusWeather.temp + "°" : "--°"
                            color: "white"
                            font.pixelSize: 42
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 20
                        InfoChip { label: "体感"; value: root.focusWeather.feelsLike + "°" }
                        InfoChip { label: "湿度"; value: root.focusWeather.humidity + "%" }
                        InfoChip { label: root.focusWeather.windDir || "风"; value: root.focusWeather.windScale + "级" }
                    }

                    Item { Layout.fillHeight: true }

                    // 城市卡片行
                    Row {
                        Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                        spacing: 16
                        Repeater {
                            model: store.trackedCities
                            CityCard {
                                cityName: modelData.name
                                cityId: modelData.id
                                isFocus: modelData.id === store.focusCityId
                                weatherData: store.cityWeather[modelData.id] || ({})
                                onClicked: function(cityId) { root.switchFocus(cityId) }
                            }
                        }
                    }
                }
            }

            // ===== Page 1: 空气质量（占位） =====
            Item {
                Text { anchors.centerIn: parent; text: "空气质量"; color: "white"; font.pixelSize: 24 }
            }

            // ===== Page 2: 天气预报（占位） =====
            Item {
                Text { anchors.centerIn: parent; text: "天气预报"; color: "white"; font.pixelSize: 24 }
            }

            // ===== Page 3: 阳光天文（占位） =====
            Item {
                Text { anchors.centerIn: parent; text: "阳光天文"; color: "white"; font.pixelSize: 24 }
            }

            // ===== Page 4: 城市详情 =====
            Item {
                Text { anchors.centerIn: parent; text: "城市详情"; color: "white"; font.pixelSize: 24 }
            }

            // ===== Page 5: 收藏 =====
            Item {
                Text { anchors.centerIn: parent; text: "收藏"; color: "white"; font.pixelSize: 24 }
            }

            // ===== Page 6: 设置 =====
            Item {
                Text { anchors.centerIn: parent; text: "设置"; color: "white"; font.pixelSize: 24 }
            }
        }
    }

    // ===== 逻辑 =====
    function switchFocus(cityId) {
        store.focusCityId = cityId
        // 加城市到追踪列表
        store.addCity({ name: root.cityNameFromSearch(cityId), id: cityId })
        weatherApi.weatherNow(cityId)
    }

    // ===== 信号 =====
    Connections {
        target: weatherApi
        function onCityLookupReady(citys) {
            searchBox.cityList = citys
            // 缓存搜索结果供 store 查名字用
            searchBox._lastResults = citys
        }
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
            let id = now._location
            store.updateWeather(id, now.temp, now.icon, now.text)
            if (id === store.focusCityId) {
                root.focusWeather = now
            }
        }
    }

    // 从搜索结果取城市名（跨函数复用）
    function cityNameFromSearch(cityId) {
        let results = searchBox.cityList
        for (let j = 0; j < results.length; j++) {
            if (results[j].id === cityId) return results[j].name
        }
        return cityId
    }
}
