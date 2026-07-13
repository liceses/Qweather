import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 960; height: 640
    visible: true
    title: "天气"

    // ===== 数据 =====
    property var cityList: []           // 追踪城市 [{name,id}]
    property int maxCities: 4           // 最多追踪城市数
    property string focusId: ""
    property var weathers: ({})         // { cityId: {temp,icon,text,...} }

    // cityList 变更时同步到 C++ store
    onCityListChanged: {
        if (typeof forecastStore !== "undefined" && forecastStore)
            forecastStore.cities = root.cityList
        if (typeof airQualityStore !== "undefined" && airQualityStore)
            airQualityStore.cities = root.cityList
        if (typeof solarAstronomyStore !== "undefined" && solarAstronomyStore)
            solarAstronomyStore.cities = root.cityList
    }

    // 焦点城市变更时同步到城市详情 Store
    onFocusIdChanged: {
        if (typeof cityDetailStore === "undefined" || !cityDetailStore) return
        for (let i = 0; i < cityList.length; i++) {
            if (cityList[i].id === focusId) {
                let c = cityList[i]
                cityDetailStore.setCity(c.id, c.name, c.lat || "", c.lon || "")
                return
            }
        }
        cityDetailStore.setCity("", "", "", "")
    }

    // ===== 背景 =====
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2e7d32" }
            GradientStop { position: 1.0; color: "#81c784" }
        }
    }

    // ===== 主布局 =====
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 左侧栏
        Rectangle {
            Layout.preferredWidth: 80
            Layout.fillHeight: true
            color: "#1a000000"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8

                Text { text: "W"; color: "white"; font.pixelSize: 28; font.bold: true; Layout.alignment: Qt.AlignHCenter }

                NavButton { label: "仪表盘"; active: stack.currentIndex === 0; onClicked: stack.currentIndex = 0 }
                NavButton { label: "预报";   active: stack.currentIndex === 1; onClicked: stack.currentIndex = 1 }
                NavButton { label: "空气";   active: stack.currentIndex === 2; onClicked: stack.currentIndex = 2 }
                NavButton { label: "天文";   active: stack.currentIndex === 3; onClicked: stack.currentIndex = 3 }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.leftMargin: 8; Layout.rightMargin: 8; color: "#20ffffff" }

                NavButton {
                    label: root.focusId ? root.cityName(root.focusId) : "城市"
                    active: stack.currentIndex === 5
                    onClicked: stack.currentIndex = 5
                }

                Item { Layout.fillHeight: true }
                NavButton { label: "设置"; active: stack.currentIndex === 4; onClicked: stack.currentIndex = 4 }
            }
        }

        // 页面区
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // Page 0: 仪表盘
            Item {
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 24

                    // 搜索框
                    SearchBar {
                        id: searchBox
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 300
                        onCitySelected: function(cityId) { root.addFocus(cityId) }
                    }

                    // 城市名
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.cityName(root.focusId) || "搜索城市开始"
                        color: "white"; font.pixelSize: 48; font.bold: true
                    }

                    // 天气摘要
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: {
                            let w = root.weathers[root.focusId]
                            if (!w) return ""
                            return (w.text || "") + "  " + (w.temp || "--") + "°"
                        }
                        color: "white"; font.pixelSize: 28
                    }

                    // 城市卡片行
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12
                        Repeater {
                            model: root.cityList
                            delegate: CityCard {
                                cityName: modelData.name
                                cityId: modelData.id
                                isFocus: modelData.id === root.focusId
                                weatherData: root.weathers[modelData.id] || ({})
                                onClicked: function(cityId) { root.addFocus(cityId) }
                            }
                        }
                    }
                }
            }

            // Page 1: 天气预报 (数据由 C++ forecastStore 驱动)
            ForecastPage {}
            AirQualityPage {}
            SolarAstronomyPage {}
            Item { Text { anchors.centerIn: parent; text: "设置"; color: "white"; font.pixelSize: 20 } }

            // Page 5: 城市详情
            CityDetailPage {}
        }
    }

    // ===== 逻辑 =====
    function addFocus(cityId) {
        // 1. 已在列表中 → 只切换焦点
        for (let i = 0; i < cityList.length; i++) {
            if (cityList[i].id === cityId) {
                focusId = cityId
                weatherApi.weatherNow(cityId)
                return
            }
        }
        // 2. 从搜索结果取城市名和坐标
        let name = cityId, lat = "", lon = ""
        let results = searchBox.cityList
        for (let j = 0; j < results.length; j++) {
            if (results[j].id === cityId) {
                name = results[j].name; lat = results[j].lat || ""; lon = results[j].lon || ""
                break
            }
        }
        // 3. 添加或替换当前焦点卡片
        let entry = { name: name, id: cityId, lat: lat, lon: lon }
        if (cityList.length < maxCities) {
            cityList.push(entry)
        } else {
            for (let k = 0; k < cityList.length; k++) {
                if (cityList[k].id === focusId) {
                    cityList[k] = entry
                    break
                }
            }
        }
        cityListChanged()
        focusId = cityId
        weatherApi.weatherNow(cityId)
    }

    function cityName(id) {
        for (let i = 0; i < cityList.length; i++) {
            if (cityList[i].id === id) return cityList[i].name
        }
        return id
    }

    // ===== 信号 =====
    Connections {
        target: weatherApi
        function onCityTopReady(cities) {
            let need = maxCities - cityList.length
            for (let i = 0; i < Math.min(cities.length, need); i++) {
                let c = cities[i]
                let dup = false
                for (let j = 0; j < cityList.length; j++) {
                    if (cityList[j].id === c.id) { dup = true; break }
                }
                if (!dup) {
                    cityList.push({ name: c.name, id: c.id, lat: c.lat || "", lon: c.lon || "" })
                    weatherApi.weatherNow(c.id)
                }
            }
            if (!focusId && cityList.length > 0) focusId = cityList[0].id
            cityListChanged()
        }
        function onWeatherNowReady(now) {
            let id = now._location
            weathers[id] = { temp: now.temp, icon: now.icon, text: now.text }
            weathersChanged()   // 通知绑定刷新
            console.log("更新天气:", id, now.temp + "°")
        }
    }

    Component.onCompleted: {
        weatherApi.topCity("cn", 4)
    }
}
