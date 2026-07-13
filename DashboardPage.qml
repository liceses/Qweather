import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// 仪表盘页面 —— 直接属性绑定（响应式），不从函数读
Item {
    id: page
    property var store: null
    property var weatherApi: null
    signal navigateToPage(int pageIndex)

    // 焦点城市天气的快捷引用（响应式绑定）
    property var fw: page.store && page.store.focusCityId
                     ? (page.store.cityWeather[page.store.focusCityId] || {}) : ({})

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40

        SearchBar {
            id: searchBox
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            weatherApi: page.weatherApi
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
            Layout.alignment: Qt.AlignHCenter; spacing: 12
            WeatherIcon {
                code: page.fw.icon || "100"; iconSize: 42
            }
            Text {
                text: page.fw.text || "--"
                color: "white"; font.pixelSize: 28
            }
            Text {
                text: page.fw.temp ? page.fw.temp + "°" : "--°"
                color: "white"; font.pixelSize: 42; font.bold: true
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter; spacing: 20
            InfoChip { label: "体感"; value: page.fw.feelsLike ? page.fw.feelsLike + "°" : "--" }
            InfoChip { label: "湿度"; value: page.fw.humidity ? page.fw.humidity + "%" : "--" }
            InfoChip { label: page.fw.windDir || "风"; value: page.fw.windScale ? page.fw.windScale + "级" : "--" }
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
                        page.navigateToPage(4)
                    }
                }
            }
        }
    }

    // 收 cityLookup 更新搜索框
    Connections {
        target: page.weatherApi
        function onCityLookupReady(citys) {
            searchBox.cityList = citys
            searchBox._lastResults = citys
        }
    }

    function addAndFocus(cityId) {
        if (!page.store || !page.weatherApi) return
        page.store.focusCityId = cityId
        let name = cityId
        let results = searchBox._lastResults
        for (let j = 0; j < results.length; j++) {
            if (results[j].id === cityId) { name = results[j].name; break }
        }
        page.store.addCity({ name: name, id: cityId })
        page.weatherApi.weatherNow(cityId)
    }
}
