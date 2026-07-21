// Main.qml — Root application window with sidebar navigation, weather data management, and city stack
// 主应用窗口 — 侧边栏导航、天气数据管理、城市栈列表
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 960; height: 640
    visible: true
    title: "天气"

    // ===== Data / 核心数据 =====
    property var cityList: []           // [EN] Stack: [0]=focusCity, [1..n]=cards / [CN] 城市栈：[0]焦点城市，[1..n]卡片
    property int maxCards: appSettings ? appSettings.maxCards : 4
    property string focusId: ""         // [EN] Currently focused city ID / [CN] 当前焦点城市 ID
    property var weathers: ({})         // [EN] { cityId: {temp,icon,text,...} } / [CN] 天气数据缓存
    property var favorites: []          // [EN] Favorite cities / [CN] 收藏城市
    property var pinned: []             // [EN] Sidebar-pinned cities / [CN] 侧边栏固定城市
    property var history: []            // [EN] Browsing history (newest first) / [CN] 浏览历史（最新在前）

    // ===== Persistence / 持久化 =====
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

    // [EN] Toggle a city's favorite status, return new state / [CN] 切换城市收藏状态，返回新状态
    function toggleFavorite(cityObj) {
        for (let i = 0; i < favorites.length; i++) {
            if (favorites[i].id === cityObj.id) {
                favorites.splice(i, 1)
                favorites = favorites.slice()
                saveFavorites(); return false
            }
        }
        favorites.push(cityObj)
        favorites = favorites.slice()
        saveFavorites()
        weatherApi.weatherNow(cityObj.id)
        return true
    }
    // [EN] Check if a city is favorited / [CN] 检查城市是否已收藏
    function isFavorite(id) {
        for (let i = 0; i < favorites.length; i++)
            if (favorites[i].id === id) return true
        return false
    }

    // [EN] Pin a city to the sidebar / [CN] 固定城市到侧边栏
    function pinCity(cityObj) {
        for (let i = 0; i < pinned.length; i++)
            if (pinned[i].id === cityObj.id) return
        pinned.push(cityObj)
        pinned = pinned.slice(); savePinned()
    }
    // [EN] Unpin a city from the sidebar / [CN] 取消固定城市
    function unpinCity(id) {
        pinned = pinned.filter(function(c) { return c.id !== id })
        savePinned()
    }
    // [EN] Check if a city is pinned / [CN] 检查城市是否已固定
    function isPinned(id) {
        for (let i = 0; i < pinned.length; i++)
            if (pinned[i].id === id) return true
        return false
    }

    // [EN] Sync city list changes to child stores / [CN] 城市列表变更时同步到子 store
    onCityListChanged: {
        if (typeof forecastStore !== "undefined" && forecastStore)
            forecastStore.cities = root.cityList
        if (typeof airQualityStore !== "undefined" && airQualityStore)
            airQualityStore.cities = root.cityList
        if (typeof solarAstronomyStore !== "undefined" && solarAstronomyStore)
            solarAstronomyStore.cities = root.cityList
    }

    readonly property bool cityFavorited: {
        let fid = focusId; let favs = favorites
        for (let i = 0; i < favs.length; i++)
            if (favs[i].id === fid) return true
        return false
    }

    // ===== Stack-based cityList management / 栈式城市列表管理 =====
    // [EN] Move a city to the top of the stack (focus position) / [CN] 将城市移至栈顶（焦点位置）
    function promoteCity(id, name, lat, lon) {
        var idx = -1
        for (var i = 0; i < cityList.length; i++)
            if (cityList[i].id === id) { idx = i; break }
        var entry
        if (idx >= 0) {
            entry = cityList[idx]; cityList.splice(idx, 1)
        } else {
            var c = findCity(id)
            entry = { name: name || (c ? c.name : id), id: id,
                      lat: lat || (c ? c.lat || "" : ""),
                      lon: lon || (c ? c.lon || "" : "") }
        }
        cityList = [entry].concat(cityList)
        if (cityList.length > maxCards + 1)
            cityList = cityList.slice(0, maxCards + 1)
        cityList = cityList.slice()
        focusId = entry.id
    }
    // [EN] Remove a city from the stack / [CN] 从栈中移除城市
    function removeCity(id) {
        var wasFocus = cityList.length > 0 && cityList[0].id === id
        for (var i = 0; i < cityList.length; i++) {
            if (cityList[i].id === id) { cityList.splice(i, 1); break }
        }
        if (cityList.length === 0) { cityList = []; cityList = cityList.slice(); return }
        cityList = cityList.slice()
        if (wasFocus) focusId = cityList[0].id
    }
    // [EN] Set a city as the focus / [CN] 将城市设为焦点
    function addFocus(cityId, optName, optLat, optLon) {
        promoteCity(cityId, optName, optLat, optLon)
    }

    property string focusName: cityList.length > 0 ? cityList[0].name : ""
    property int stateIndex: 0

    readonly property string sidebarCityId: {
        if (pinned.length > 0)     return pinned[0].id
        if (favorites.length > 0)  return favorites[0].id
        if (history.length > 0)    return history[0].id
        return focusId || ""
    }

    // [EN] When focus changes, fetch weather, astronomy data & update background / [CN] 焦点切换时获取天气、天文数据并更新背景
    onFocusIdChanged: {
        if (focusId) {
            addHistoryEntry(focusId)
            weatherApi.weatherNow(focusId)
            var today = new Date().toISOString().slice(0,10).replace(/-/g,"")
            weatherApi.astronomySun(focusId, today, focusId)
            weatherApi.astronomyMoon(focusId, today, focusId)
        }
        if (typeof cityDetailStore === "undefined" || !cityDetailStore) return
        var top = cityList[0]
        if (top) {
            cityDetailStore.setCity(top.id, top.name, top.lat || "", top.lon || "")
            if (top.lat && top.lon)
                backgroundManager.setLocation(parseFloat(top.lat), parseFloat(top.lon))
        } else cityDetailStore.setCity("", "", "", "")
    }

    // ===== Dynamic weather background / 动态天气背景 =====
    WeatherBackground {
        id: weatherBg
        anchors.fill: parent
        z: -1
    }

    // [EN] Dark overlay adapts to sky exposure / [CN] 根据天空曝光度叠加黑色遮罩
    Rectangle {
        anchors.fill: parent
        z: 0
        color: "#000000"
        opacity: {
            var exp = backgroundManager ? backgroundManager.skyState.exposure : 0
            var raw = (exp - 1.2) / 0.6
            return Math.max(0, Math.min(raw, 1.0)) * 0.2
        }
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }

    WeatherBackgroundDebugPanel {
        id: debugPanel
        z: 100
    }

    // ===== Main layout / 主布局 =====
    // [EN] Captures mouse for parallax effect, no clicks / [CN] 捕获鼠标实现视差效果，不处理点击
    MouseArea {
        id: parallaxArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.ArrowCursor
        onPositionChanged: {
            var px = Math.max(-1, Math.min(1, (mouseX / width - 0.5) * 2.0))
            var py = Math.max(-1, Math.min(1, (mouseY / height - 0.5) * 2.0))
            weatherBg.parallaxX = px
            weatherBg.parallaxY = py
            backgroundManager.setParallax(px, py)
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

        // [EN] Left sidebar navigation / [CN] 左侧导航栏
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

                Item {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: logoTxt.implicitWidth
                    Layout.preferredHeight: 40

                    Text {
                        id: logoTxt
                        anchors.centerIn: parent
                        text: sidebar.sidebarExpanded ? "QWeather" : "Q"
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

                NavButton { icon: "qrc:/icons/squares-four.svg"; label: "仪表盘"; expanded: sidebar.sidebarExpanded; active: root.stateIndex === 0; onClicked: root.stateIndex = 0 }
                NavButton { icon: "qrc:/icons/calendar.svg";     label: "天气预报";   expanded: sidebar.sidebarExpanded; active: root.stateIndex === 1; onClicked: root.stateIndex = 1 }
                NavButton { icon: "qrc:/icons/air-filter.svg";   label: "空气质量";   expanded: sidebar.sidebarExpanded; active: root.stateIndex === 2; onClicked: root.stateIndex = 2 }
                NavButton { icon: "qrc:/icons/sun-horizon.svg";  label: (appSettings && !appSettings.showSolarRadiation) ? "朝夕月相" : "天文"; expanded: sidebar.sidebarExpanded; active: root.stateIndex === 3; onClicked: root.stateIndex = 3 }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.leftMargin: 8; Layout.rightMargin: 8; color: "#20ffffff" }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: midCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: midCol
                        width: parent.width

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
                                active: root.stateIndex === 5 && root.focusId === modelData.id
                                onClicked: {
                                    root.promoteCity(modelData.id)
                                    root.stateIndex = 5
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 1
                            Layout.leftMargin: 8; Layout.rightMargin: 8
                            color: "#20ffffff"
                        }

                        NavButton { icon: "qrc:/icons/star.svg"; label: "收藏"; expanded: sidebar.sidebarExpanded; active: root.stateIndex === 6; onClicked: root.stateIndex = 6 }
                    }
                }

                NavButton { icon: "qrc:/icons/gear-six.svg"; label: "设置"; expanded: sidebar.sidebarExpanded; active: root.stateIndex === 4; onClicked: root.stateIndex = 4 }
            }
        }

        // [EN] Page area with cross-fade / [CN] 页面区（交叉淡入淡出）
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.stateIndex

            DashboardPage {
                opacity: stack.currentIndex === 0 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                cityList: root.cityList
                focusId: root.focusId
                focusName: root.focusName
                weathers: root.weathers
                onCitySelected: function(cityId, cityName, lat, lon) {
                    root.addFocus(cityId, cityName, lat, lon)
                }
                onFocusRequested: function(cityId) {
                    root.addFocus(cityId)
                }
                onNavigateToDetail: function(cityId) {
                    root.promoteCity(cityId)
                    root.stateIndex = 5
                }
                onCloseRequested: function(cityId) {
                    root.removeCity(cityId)
                }
            }

            ForecastPage {
                opacity: stack.currentIndex === 1 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            AirQualityPage {
                opacity: stack.currentIndex === 2 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            SolarAstronomyPage {
                opacity: stack.currentIndex === 3 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }
            SettingsPage {
                opacity: stack.currentIndex === 4 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                weatherCache: weatherCache
            }

            CityDetailPage {
                opacity: stack.currentIndex === 5 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                favorited: root.cityFavorited
                onToggleFav: function() {
                    let fid = root.focusId
                    if (!fid) return
                    let c = root.findCity(fid)
                    if (!c) {
                        let d = cityDetailStore.detail
                        c = { name: d.cityName || fid, id: fid, lat: "", lon: "" }
                    }
                    root.toggleFavorite(c)
                }
            }

            FavoritesPage {
                opacity: stack.currentIndex === 6 ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                id: favPage
                favorites: root.favorites
                pinned: root.pinned
                weathers: root.weathers
                onCityClicked: function(cityId) { root.promoteCity(cityId) }
                onPinToggled: function(cityObj) {
                    if (root.isPinned(cityObj.id)) root.unpinCity(cityObj.id)
                    else root.pinCity(cityObj)
                }
                onCityDoubleClicked: function(cityId) {
                    root.promoteCity(cityId)
                    root.stateIndex = 5
                }
            }
        }
        }  // RowLayout
    }  // parallaxArea

    // ===== Logic helpers / 逻辑辅助函数 =====
    // [EN] Lookup city name by ID across all lists / [CN] 跨所有列表按 ID 查找城市名称
    function cityName(id) {
        let all = cityList.concat(favorites, pinned, history)
        for (let i = 0; i < all.length; i++) {
            if (all[i].id === id) return all[i].name
        }
        return id
    }
    // [EN] Find city object by ID across all lists / [CN] 跨所有列表按 ID 查找城市对象
    function findCity(id) {
        let all = cityList.concat(favorites, pinned, history)
        for (let i = 0; i < all.length; i++)
            if (all[i].id === id) return all[i]
        return null
    }
    // [EN] Add a city to browsing history / [CN] 将城市添加到浏览历史
    function addHistoryEntry(cityId) {
        let c = findCity(cityId)
        if (!c) return
        history = history.filter(function(h) { return h.id !== cityId })
        history.unshift({ name: c.name, id: cityId, lat: c.lat || "", lon: c.lon || "" })
        if (history.length > 20) history.pop()
        saveHistory()
    }

    // ===== Signal connections to weatherApi / 天气 API 信号连接 =====
    Connections {
        target: weatherApi
        // [EN] Top cities fetched, populate cityList / [CN] 热门城市数据到达，填充 cityList
        function onCityTopReady(cities) {
            let need = maxCards + 1 - cityList.length
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
            if (!focusId && cityList.length > 0) {
                focusId = cityList[0].id
                cityList = cityList.slice();
            }
        }
        // [EN] Current weather data received, update weathers map & background / [CN] 实时天气数据到达，更新 weathers 映射和背景
        function onWeatherNowReady(now) {
            let id = now._location
            let w = Object.assign({}, weathers)
            w[id] = { temp: now.temp, icon: now.icon, text: now.text }
            weathers = w

            backgroundManager.updateWeather(parseInt(now.icon))
        }
        // [EN] Solar astronomy data received, update background sun times / [CN] 太阳天文数据到达，更新背景日出日落时间
        function onAstronomySunReady(cityId, result) {
            if (cityId !== root.focusId || !result.sunrise) return
            backgroundManager.updateSunTimes(result.sunrise, result.sunset)
        }
        // [EN] Lunar astronomy data received, update background moon phase / [CN] 月球天文数据到达，更新背景月相
        function onAstronomyMoonReady(cityId, result) {
            if (cityId !== root.focusId) return
            var phases = result.moonPhase
            if (phases && phases.length > 0) {
                var p = phases[0]
                backgroundManager.updateMoonData(parseInt(p.icon), parseFloat(p.illumination))
            }
        }
    }

    // [EN] Init: load persisted data, fetch top cities and favorites / [CN] 初始化：加载持久化数据、获取热门城市和收藏天气
    Component.onCompleted: {
        loadSettings()
        weatherApi.topCity("cn", maxCards + 1)
        for (let i = 0; i < favorites.length; i++) {
            weatherApi.weatherNow(favorites[i].id)
        }
    }

    // [EN] Keep QML engine alive with a perpetual animation / [CN] 保持 QML 引擎运行（无限循环动画）
    Item {
        NumberAnimation on opacity {
            from: 0.999; to: 1.0; duration: 100
            loops: Animation.Infinite
        }
    }
}
