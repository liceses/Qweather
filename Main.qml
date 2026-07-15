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
    property var favorites: []          // 收藏城市
    property var pinned: []             // 侧边栏固定城市
    property var history: []            // 浏览历史（最新在前）

    // ===== 持久化 =====
    function loadSettings() {
        let favJson = weatherCache.load("fav_cities")
        let pinJson = weatherCache.load("pin_cities")
        let histJson = weatherCache.load("hist_cities")
        if (favJson) favorites = JSON.parse(favJson)
        if (pinJson) pinned = JSON.parse(pinJson)
        if (histJson) history = JSON.parse(histJson)
    }
    function saveFavorites() { weatherCache.save("fav_cities", JSON.stringify(favorites)) }
    function savePinned()    { weatherCache.save("pin_cities", JSON.stringify(pinned)) }
    function saveHistory()   { weatherCache.save("hist_cities", JSON.stringify(history)) }

    // 收藏切换
    function toggleFavorite(cityObj) {
        for (let i = 0; i < favorites.length; i++) {
            if (favorites[i].id === cityObj.id) {
                favorites.splice(i, 1)
                favorites = favorites.slice()   // 新引用触发绑定
                saveFavorites(); return false
            }
        }
        favorites.push(cityObj)
        favorites = favorites.slice()
        saveFavorites()
        // 新收藏的城市获取天气数据，确保收藏页面不会显示 "--"
        weatherApi.weatherNow(cityObj.id)
        return true
    }
    function isFavorite(id) {
        for (let i = 0; i < favorites.length; i++)
            if (favorites[i].id === id) return true
        return false
    }

    // 固定/取消固定
    function pinCity(cityObj) {
        for (let i = 0; i < pinned.length; i++)
            if (pinned[i].id === cityObj.id) return
        pinned.push(cityObj)
        pinned = pinned.slice(); savePinned()
    }
    function unpinCity(id) {
        pinned = pinned.filter(function(c) { return c.id !== id })
        savePinned()
    }
    function isPinned(id) {
        for (let i = 0; i < pinned.length; i++)
            if (pinned[i].id === id) return true
        return false
    }

    // cityList 变更时同步到 C++ store
    onCityListChanged: {
        if (typeof forecastStore !== "undefined" && forecastStore)
            forecastStore.cities = root.cityList
        if (typeof airQualityStore !== "undefined" && airQualityStore)
            airQualityStore.cities = root.cityList
        if (typeof solarAstronomyStore !== "undefined" && solarAstronomyStore)
            solarAstronomyStore.cities = root.cityList
    }

    // 当前焦点城市是否已收藏
    readonly property bool cityFavorited: {
        let fid = focusId; let favs = favorites
        for (let i = 0; i < favs.length; i++)
            if (favs[i].id === fid) return true
        return false
    }

    // 侧边栏城市分区 ID — 优先级：固定[0] > 收藏[0] > 历史[0] > 焦点
    readonly property string sidebarCityId: {
        if (pinned.length > 0)     return pinned[0].id
        if (favorites.length > 0)  return favorites[0].id
        if (history.length > 0)    return history[0].id
        return focusId || ""
    }

    // 焦点城市变更时：记录历史 + 刷新天气 + 同步城市详情 Store
    onFocusIdChanged: {
        if (focusId) {
            addHistoryEntry(focusId)
            weatherApi.weatherNow(focusId)
        }
        if (typeof cityDetailStore === "undefined" || !cityDetailStore) return
        let c = findCity(focusId)
        if (c) cityDetailStore.setCity(c.id, c.name, c.lat || "", c.lon || "")
        else cityDetailStore.setCity("", "", "", "")
    }

    // ===== 动态天气背景（V3 天空模拟系统） =====
    WeatherBackground {
        id: weatherBg
        anchors.fill: parent
        z: -1  // 确保在所有 UI 元素之后
    }

    WeatherBackgroundDebugPanel {
        id: debugPanel
        z: 100
    }

    // ===== 主布局 =====
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 左侧栏
        Rectangle {
            id: sidebar
            property bool sidebarExpanded: false
            Layout.preferredWidth: sidebar.sidebarExpanded ? 200 : 80
            Layout.fillHeight: true
            color: "#1a000000"

            Behavior on Layout.preferredWidth {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8

                // Logo —— 点击切换侧边栏展开/收起
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: logoTxt.implicitWidth
                    Layout.preferredHeight: 40

                    Text {
                        id: logoTxt
                        anchors.centerIn: parent
                        text: sidebar.sidebarExpanded ? "Weather" : "W"
                        color: "white"
                        font.pixelSize: sidebar.sidebarExpanded ? 22 : 28
                        font.bold: true
                        Behavior on font.pixelSize { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sidebar.sidebarExpanded = !sidebar.sidebarExpanded
                    }
                }

                NavButton { icon: "qrc:/icons/squares-four.svg"; label: "仪表盘"; expanded: sidebar.sidebarExpanded; active: stack.currentIndex === 0; onClicked: stack.currentIndex = 0 }
                NavButton { icon: "qrc:/icons/calendar.svg";     label: "天气预报";   expanded: sidebar.sidebarExpanded; active: stack.currentIndex === 1; onClicked: stack.currentIndex = 1 }
                NavButton { icon: "qrc:/icons/air-filter.svg";   label: "空气质量";   expanded: sidebar.sidebarExpanded; active: stack.currentIndex === 2; onClicked: stack.currentIndex = 2 }
                NavButton { icon: "qrc:/icons/sun-horizon.svg";  label: (appSettings && !appSettings.showSolarRadiation) ? "朝夕月相" : "天文"; expanded: sidebar.sidebarExpanded; active: stack.currentIndex === 3; onClicked: stack.currentIndex = 3 }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.leftMargin: 8; Layout.rightMargin: 8; color: "#20ffffff" }

                // === 可滚动中间区：城市分区 + 收藏 ===
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: midCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: midCol
                        width: parent.width

                        // 侧边栏城市分区：固定城市列表 或 优先级城市
                        Repeater {
                            model: root.pinned.length > 0 ? root.pinned
                                  : (root.sidebarCityId ? [{ id: root.sidebarCityId }] : [])
                            NavButton {
                                icon: "qrc:/icons/map-pin-simple.svg"
                                expanded: sidebar.sidebarExpanded
                                Layout.alignment: Qt.AlignHCenter
                                label: {
                                    let n = root.cityName(modelData.id)
                                    return (root.pinned.length === 0 && index === 0 && n === modelData.id)
                                           ? "城市详情" : n
                                }
                                active: stack.currentIndex === 5 && root.focusId === modelData.id
                                onClicked: {
                                    root.focusId = modelData.id
                                    stack.currentIndex = 5
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 1
                            Layout.leftMargin: 8; Layout.rightMargin: 8
                            color: "#20ffffff"
                        }

                        NavButton { icon: "qrc:/icons/star.svg"; label: "收藏"; expanded: sidebar.sidebarExpanded; active: stack.currentIndex === 6; onClicked: stack.currentIndex = 6 }
                    }
                }

                NavButton { icon: "qrc:/icons/gear-six.svg"; label: "设置"; expanded: sidebar.sidebarExpanded; active: stack.currentIndex === 4; onClicked: stack.currentIndex = 4 }
            }
        }

        // 页面区
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // Page 0: 仪表盘
            DashboardPage {
                cityList: root.cityList
                focusId: root.focusId
                weathers: root.weathers
                onCitySelected: function(cityId, cityName, lat, lon) {
                    root.addFocus(cityId, cityName, lat, lon)
                }
                onFocusRequested: function(cityId) {
                    root.addFocus(cityId)
                }
                onNavigateToDetail: function(cityId) {
                    root.focusId = cityId
                    stack.currentIndex = 5
                }
            }

            // Page 1: 天气预报 (数据由 C++ forecastStore 驱动)
            ForecastPage {}
            AirQualityPage {}
            SolarAstronomyPage {}
            SettingsPage { weatherCache: weatherCache }

            // Page 5: 城市详情
            CityDetailPage {
                favorited: root.cityFavorited
                onToggleFav: function() {
                    let fid = root.focusId
                    if (!fid) return
                    console.log("收藏切换:", fid, "已收藏:", root.isFavorite(fid))
                    let c = root.findCity(fid)
                    if (!c) {
                        // 从 detail 中获取城市信息
                        let d = cityDetailStore.detail
                        c = { name: d.cityName || fid, id: fid, lat: "", lon: "" }
                    }
                    root.toggleFavorite(c)
                }
            }

            // Page 6: 收藏
            FavoritesPage {
                id: favPage
                favorites: root.favorites
                pinned: root.pinned
                weathers: root.weathers
                onCityClicked: function(cityId) { root.addFocus(cityId) }
                onPinToggled: function(cityObj) {
                    if (root.isPinned(cityObj.id)) root.unpinCity(cityObj.id)
                    else root.pinCity(cityObj)
                }
                onCityDoubleClicked: function(cityId) {
                    root.focusId = cityId
                    stack.currentIndex = 5
                }
            }
        }
    }

    // ===== 逻辑 =====
    function cityName(id) {
        let all = cityList.concat(favorites, pinned, history)
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === id) return all[i].name
        }
        return id
    }
    function findCity(id) {
        let all = cityList.concat(favorites, pinned, history)
        for (let i = 0; i < all.length; i++)
            if (all[i].id === id) return all[i]
        return null
    }
    function addHistoryEntry(cityId) {
        let c = findCity(cityId)
        if (!c) return
        history = history.filter(function(h) { return h.id !== cityId })
        history.unshift({ name: c.name, id: cityId, lat: c.lat || "", lon: c.lon || "" })
        if (history.length > 20) history.pop()
        saveHistory()
    }

    function addFocus(cityId, optName, optLat, optLon) {
        // 已在列表中 → 只切换焦点
        for (let i = 0; i < cityList.length; i++) {
            if (cityList[i].id === cityId) {
                focusId = cityId
                weatherApi.weatherNow(cityId)
                return
            }
        }
        // 从各列表找城市信息，优先用传入参数
        let c = findCity(cityId)
        let name = c ? c.name : (optName || cityId)
        let lat = c ? (c.lat || "") : (optLat || "")
        let lon = c ? (c.lon || "") : (optLon || "")
        let entry = { name: name, id: cityId, lat: lat, lon: lon }
        if (cityList.length < maxCities) {
            cityList.push(entry)
        } else {
            for (let k = 0; k < cityList.length; k++) {
                if (cityList[k].id === focusId) {
                    cityList[k] = entry; break
                }
            }
        }
        cityList = cityList.slice()
        focusId = cityId
        weatherApi.weatherNow(cityId)
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
            cityList = cityList.slice()
        }
        function onWeatherNowReady(now) {
            let id = now._location
            let w = Object.assign({}, weathers)
            w[id] = { temp: now.temp, icon: now.icon, text: now.text }
            weathers = w
        }
    }

    Component.onCompleted: {
        loadSettings()
        weatherApi.topCity("cn", 4)
        // 收藏城市也需要获取天气数据，否则打开收藏页面显示 "--"
        for (let i = 0; i < favorites.length; i++) {
            weatherApi.weatherNow(favorites[i].id)
        }
    }
}
