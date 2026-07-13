import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// 仪表盘页面 —— 搜索框 + 焦点天气摘要 + 城市卡片行
Item {
    id: page
    property var store: null
    property var weatherApi: null
    signal navigateToPage(int pageIndex)
    signal focusOnCity(string cityId)

    // 从 store 取当前焦点城市的天气数据（计算属性，跟随 store 自动更新）
    function w(key) {
        if (!store || !store.focusCityId) return "--"
        let d = store.cityWeather[store.focusCityId]
        return d ? (d[key] || "--") : "--"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40

        SearchBar {
            id: searchBox
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            property var _lastResults: []
            onCitySelected: function(cityId) {
                page.addAndFocus(cityId)
            }
        }

        Item { Layout.preferredHeight: 40 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: page.store ? page.store.cityName(page.store.focusCityId) || "搜索城市开始" : ""
            color: "white"
            font.pixelSize: 56
            font.bold: true
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            WeatherIcon {
                code: page.w("icon") === "--" ? "100" : page.w("icon")
                iconSize: 42
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: page.w("text")
                color: "white"
                font.pixelSize: 28
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: page.w("temp") === "--" ? "--°" : page.w("temp") + "°"
                color: "white"
                font.pixelSize: 42
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            InfoChip {
                label: "体感"
                value: page.w("feelsLike") === "--" ? "--" : page.w("feelsLike") + "°"
            }
            InfoChip {
                label: "湿度"
                value: page.w("humidity") === "--" ? "--" : page.w("humidity") + "%"
            }
            InfoChip {
                label: page.w("windDir") === "--" ? "风" : page.w("windDir")
                value: page.w("windScale") === "--" ? "--" : page.w("windScale") + "级"
            }
        }

        Item { Layout.fillHeight: true }

        Row {
            Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
            spacing: 16
            Repeater {
                model: page.store ? page.store.trackedCities : []
                CityCard {
                    cityName: modelData.name
                    cityId: modelData.id
                    isFocus: modelData.id === (page.store ? page.store.focusCityId : "")
                    weatherData: page.store ? (page.store.cityWeather[modelData.id] || {}) : ({})
                    onClicked: function(cityId) { page.addAndFocus(cityId) }
                    onDoubleClicked: function(cityId) {
                        page.store.focusCityId = cityId
                        page.navigateToPage(4)   // 跳转城市详情页
                    }
                }
            }
        }
    }

    function addAndFocus(cityId) {
        if (!page.store || !page.weatherApi) return
        page.store.focusCityId = cityId
        // 从搜索结果取城市名
        let name = cityId
        let results = searchBox._lastResults
        for (let j = 0; j < results.length; j++) {
            if (results[j].id === cityId) { name = results[j].name; break }
        }
        page.store.addCity({ name: name, id: cityId })
        page.weatherApi.weatherNow(cityId)
    }
}
