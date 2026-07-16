import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 960; height: 640
    visible: true
    title: "天气"

    // ===== 数据 =====
    property var cityList: []           // 栈: [0]=focusCity, [1..n]=cards
    property int maxCards: appSettings ? appSettings.maxCards : 4
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

    // ===== 栈式 cityList 管理 =====
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
    function removeCity(id) {
        var wasFocus = cityList.length > 0 && cityList[0].id === id
        for (var i = 0; i < cityList.length; i++) {
            if (cityList[i].id === id) { cityList.splice(i, 1); break }
        }
        if (cityList.length === 0) { cityList = []; cityList = cityList.slice(); return }
        cityList = cityList.slice()
        if (wasFocus) focusId = cityList[0].id
    }
    function addFocus(cityId, optName, optLat, optLon) {
        promoteCity(cityId, optName, optLat, optLon)
    }

    // 焦点城市名 — 从栈顶推导
    property string focusName: cityList.length > 0 ? cityList[0].name : ""

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

    // ===== 动态天气背景（V3 天空模拟系统） =====
    WeatherBackground {
        id: weatherBg
        anchors.fill: parent
        z: -1  // 确保在所有 UI 元素之后
    }

    // 自适应曝光遮罩 — 仅强光下压暗, 改善文字可读性
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

    // ===== 主布局（视差 MouseArea 为卡片 MouseArea 的父级） =====
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
                                    root.promoteCity(modelData.id)
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
                    stack.currentIndex = 5
                }
                onCloseRequested: function(cityId) {
                    root.removeCity(cityId)
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
                onCityClicked: function(cityId) { root.promoteCity(cityId) }
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
        }  // RowLayout (ends inside parallaxArea)
    }  // parallaxArea

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


    // ===== 信号 =====
    Connections {
        target: weatherApi
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
        function onWeatherNowReady(now) {
            let id = now._location
            let w = Object.assign({}, weathers)
            w[id] = { temp: now.temp, icon: now.icon, text: now.text }
            weathers = w

            // 转发到动态背景系统
            var iconCode = parseInt(now.icon)
            var isDay = !(iconCode >= 150 && iconCode <= 199)
            backgroundManager.updateWeather(iconCode, isDay)
        }
        function onAstronomySunReady(cityId, result) {
            if (cityId !== root.focusId || !result.sunrise) return
            backgroundManager.updateSunTimes(result.sunrise, result.sunset)
        }
        function onAstronomyMoonReady(cityId, result) {
            if (cityId !== root.focusId) return
            var phases = result.moonPhase
            if (phases && phases.length > 0) {
                var p = phases[0]
                backgroundManager.updateMoonData(parseInt(p.icon), parseFloat(p.illumination))
            }
        }
    }

    Component.onCompleted: {
        loadSettings()
        weatherApi.topCity("cn", maxCards + 1)
        // 收藏城市也需要获取天气数据，否则打开收藏页面显示 "--"
        for (let i = 0; i < favorites.length; i++) {
            weatherApi.weatherNow(favorites[i].id)
        }
    }

    // 渲染泵：强制 Qt Quick 持续渲染，防止鼠标静止时帧率下降
    Item {
        NumberAnimation on opacity {
            from: 0.999; to: 1.0; duration: 100
            loops: Animation.Infinite
        }
    }
}
