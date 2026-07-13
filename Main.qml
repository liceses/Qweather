import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ApplicationWindow {
    id: root
    width: 1280
    height: 720
    visible: true
    title: "天气"

    // ===== 全局数据 =====
    property string focusCityId: ""
    property string focusCityName: "北京"
    property var focusWeather: ({})
    property var cityList: []            // 已追踪的城市 [{name, id}]

    // 卡片列表（Dashboard 用）
    ListModel {
        id: cardModel
    }

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
            focusCityName: root.focusCityName
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

                    SearchBar {
                        id: searchBox
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        onCitySelected: function(cityId) {
                            root.addCityCard(cityId)
                            root.switchFocus(cityId)
                        }
                    }

                    Item { Layout.preferredHeight: 40 }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.focusCityName
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
                            model: cardModel
                            CityCard {
                                cityName: model.name
                                cityId: model.id
                                isFocus: model.focus
                                weatherData: ({ temp: model.temp, icon: model.icon, text: model.text })
                                onClicked: function(cityId) { root.switchFocus(cityId) }
                            }
                        }
                    }
                }
            }

            // ========== Page 1: 空气质量（占位） ==========
            Item {
                Text { anchors.centerIn: parent; text: "空气质量"; color: "white"; font.pixelSize: 24 }
            }

            // ========== Page 2: 天气预报（占位） ==========
            Item {
                Text { anchors.centerIn: parent; text: "天气预报"; color: "white"; font.pixelSize: 24 }
            }

            // ========== Page 3: 阳光天文（占位） ==========
            Item {
                Text { anchors.centerIn: parent; text: "阳光天文"; color: "white"; font.pixelSize: 24 }
            }

            // ========== Page 4: 城市详情（占位，步骤 8 实现） ==========
            Item {
                Text { anchors.centerIn: parent; text: "城市详情"; color: "white"; font.pixelSize: 24 }
            }

            // ========== Page 5: 收藏（占位） ==========
            Item {
                Text { anchors.centerIn: parent; text: "收藏"; color: "white"; font.pixelSize: 24 }
            }

            // ========== Page 6: 设置（占位） ==========
            Item {
                Text { anchors.centerIn: parent; text: "设置"; color: "white"; font.pixelSize: 24 }
            }
        }
    }

    // ===== 逻辑函数 =====
    function switchFocus(cityId) {
        root.focusCityId = cityId
        weatherApi.weatherNow(cityId)
        for (let i = 0; i < cardModel.count; i++) {
            cardModel.setProperty(i, "focus", cardModel.get(i).id === cityId)
        }
    }

    function addCityCard(cityId) {
        for (let i = 0; i < cardModel.count; i++) {
            if (cardModel.get(i).id === cityId) return
        }
        let name = cityId
        for (let j = 0; j < searchBox.cityList.length; j++) {
            if (searchBox.cityList[j].id === cityId) {
                name = searchBox.cityList[j].name; break
            }
        }
        cardModel.append({ name: name, id: cityId, temp: "", icon: "", text: "", focus: false })
        weatherApi.weatherNow(cityId)
    }

    // ===== 信号连接 =====
    Connections {
        target: weatherApi
        function onCityLookupReady(citys) {
            searchBox.cityList = citys
        }
        function onCityTopReady(cities) {
            for (let i = 0; i < Math.min(cities.length, 4); i++) {
                let c = cities[i]
                let dup = false
                for (let j = 0; j < cardModel.count; j++) {
                    if (cardModel.get(j).id === c.id) { dup = true; break }
                }
                if (!dup) {
                    cardModel.append({ name: c.name, id: c.id, temp: "", icon: "", text: "", focus: false })
                    weatherApi.weatherNow(c.id)
                }
            }
            if (root.focusCityId === "" && cardModel.count > 0) {
                root.switchFocus(cardModel.get(0).id)
                root.focusCityName = cardModel.get(0).name
            }
        }
        function onWeatherNowReady(now) {
            let id = now._location
            for (let i = 0; i < cardModel.count; i++) {
                if (cardModel.get(i).id === id) {
                    cardModel.setProperty(i, "temp", now.temp)
                    cardModel.setProperty(i, "icon", now.icon)
                    cardModel.setProperty(i, "text", now.text)
                }
            }
            if (id === root.focusCityId) {
                root.focusWeather = now
            }
        }
    }
}
