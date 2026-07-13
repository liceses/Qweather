import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    visible: true
    title: "天气"

    // ===== 数据模型 =====
    property string focusCityId: ""
    property var focusWeather: ({})       // 焦点城市实时天气
    property var cityTemps: ({})          // { cityId : { temp, icon, text } }

    // 卡片列表
    ListModel {
        id: cardModel
        // 元素: { name, id, temp, icon, text, focus }
    }

    // ===== 初始化：加载热门城市 =====
    Component.onCompleted: {
        weatherApi.topCity("cn", 4)
    }

    // ===== Layer 0: 背景 =====
    Rectangle {
        id: bg
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
            Layout.preferredWidth: 80
            Layout.fillHeight: true
            onPageChanged: function(page) { mainStack.currentIndex = page }
        }

        StackLayout {
            id: mainStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            // ========== Page 0: 仪表盘 ==========
            Item {
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 40

                    // 搜索框
                    SearchBar {
                        id: searchBox
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        onCitySelected: function(cityId) {
                            addCityCard(cityId)
                            switchFocus(cityId)
                        }
                    }

                    // 弹性空白
                    Item { Layout.preferredHeight: 40 }

                    // 焦点城市名
                    Text {
                        id: cityNameText
                        Layout.alignment: Qt.AlignHCenter
                        text: root.focusWeather._location || "搜索城市开始"
                        color: "white"
                        font.pixelSize: 56
                        font.bold: true
                    }

                    // 天气摘要行
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        WeatherIcon {
                            id: mainIcon
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

                    // 副信息：体感、湿度、风力
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
                            model: cardModel
                            CityCard {
                                cityName: model.name
                                cityId: model.id
                                isFocus: model.focus
                                weatherData: ({ temp: model.temp, icon: model.icon, text: model.text })
                                onClicked: function(cityId) { switchFocus(cityId) }
                            }
                        }

                        // 添加按钮
                        AddCityButton {
                            onClicked: { searchBox.forceActiveFocus() }
                        }
                    }
                }
            }

            // ========== Page 1: 收藏（占位） ==========
            Item {
                Text {
                    anchors.centerIn: parent
                    text: "收藏"
                    color: "white"
                    font.pixelSize: 24
                }
            }

            // ========== Page 2: 设置（占位） ==========
            Item {
                Text {
                    anchors.centerIn: parent
                    text: "设置"
                    color: "white"
                    font.pixelSize: 24
                }
            }
        }
    }

    // ===== 逻辑函数 =====
    function switchFocus(cityId) {
        root.focusCityId = cityId
        weatherApi.weatherNow(cityId)
        // 更新卡片焦点
        for (let i = 0; i < cardModel.count; i++) {
            cardModel.setProperty(i, "focus", cardModel.get(i).id === cityId)
        }
    }

    function addCityCard(cityId) {
        // 查重
        for (let i = 0; i < cardModel.count; i++) {
            if (cardModel.get(i).id === cityId) return
        }
        // 从搜索结果取 name
        let name = cityId
        for (let j = 0; j < searchBox.cityList.length; j++) {
            if (searchBox.cityList[j].id === cityId) {
                name = searchBox.cityList[j].name
                break
            }
        }
        cardModel.append({ name: name, id: cityId, temp: "", icon: "", text: "", focus: false })
        // 即时查天气
        weatherApi.weatherNow(cityId)
    }

    function updateCityWeather(cityId, temp, icon, text) {
        for (let i = 0; i < cardModel.count; i++) {
            if (cardModel.get(i).id === cityId) {
                cardModel.setProperty(i, "temp", temp)
                cardModel.setProperty(i, "icon", icon)
                cardModel.setProperty(i, "text", text)
            }
        }
    }

    // ===== 信号连接 =====
    Connections {
        target: weatherApi
        function onCityLookupReady(citys) {
            searchBox.cityList = citys
        }
        function onCityTopReady(cities) {
            // 热门城市初始化卡片
            for (let i = 0; i < Math.min(cities.length, 4); i++) {
                let c = cities[i]
                // 查重
                let dup = false
                for (let j = 0; j < cardModel.count; j++) {
                    if (cardModel.get(j).id === c.id) { dup = true; break }
                }
                if (!dup) {
                    cardModel.append({ name: c.name, id: c.id, temp: "", icon: "", text: "", focus: false })
                    weatherApi.weatherNow(c.id)
                }
            }
            // 默认焦点第一个
            if (root.focusCityId === "" && cardModel.count > 0) {
                switchFocus(cardModel.get(0).id)
            }
        }
        function onWeatherNowReady(now) {
            let id = now._location
            updateCityWeather(id, now.temp, now.icon, now.text)
            if (id === root.focusCityId) {
                root.focusWeather = now
            }
        }
    }
}
