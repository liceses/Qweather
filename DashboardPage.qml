import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

// 仪表盘页面 —— 搜索框 + 焦点天气摘要 + 城市卡片行
Item {
    id: page
    property var store: null       // CityStore 引用（外部注入）
    property var weatherApi: null

    // 焦点天气副本
    property var focusWeather: ({})

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40

        SearchBar {
            id: searchBox
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            property var _lastResults: []
            onCitySelected: function(cityId) {
                page.addAndFocus(cityId)
                searchBox._lastResults = cityList  // 缓存搜索结果
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
                code: page.focusWeather.icon || "100"
                iconSize: 42
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: page.focusWeather.text || "--"
                color: "white"
                font.pixelSize: 28
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: page.focusWeather.temp ? page.focusWeather.temp + "°" : "--°"
                color: "white"
                font.pixelSize: 42
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            InfoChip { label: "体感"; value: page.focusWeather.feelsLike + "°" }
            InfoChip { label: "湿度"; value: page.focusWeather.humidity + "%" }
            InfoChip { label: page.focusWeather.windDir || "风"; value: page.focusWeather.windScale + "级" }
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
                }
            }
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
