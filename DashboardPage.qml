// DashboardPage.qml — Dashboard with search, city name, weather display, and city cards
// 仪表盘页 — 搜索框、城市名显示、实时天气、城市卡片
import QtQuick
import QtQuick.Layouts

Item {
    id: page

    // ===== Input properties (injected by Main.qml) / 输入属性（Main.qml 绑定注入） =====
    property var cityList: []
    property string focusId: ""
    property string focusName: ""
    property var weathers: ({})

    // ===== Signals (reported to Main.qml) / 信号（上报给 Main.qml 处理） =====
    signal citySelected(string cityId, string cityName, string lat, string lon)
    signal focusRequested(string cityId)
    signal navigateToDetail(string cityId)
    signal closeRequested(string cityId)

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24

        // [EN] Search bar for city lookup / [CN] 城市搜索框
        SearchBar {
            id: searchBox
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 300
            onCitySelected: function(cityId, cityName, lat, lon) {
                page.citySelected(cityId, cityName, lat, lon)
            }
        }

        // [EN] City name title — click = focus, double-click = detail / [CN] 城市名称标题 — 单击切换焦点，双击查看详情
        Text {
            id: cityNameText
            Layout.alignment: Qt.AlignHCenter
            text: page.focusName || "搜索城市开始"
            color: "white"; font.pixelSize: 48; font.bold: true
            Behavior on opacity { NumberAnimation { duration: 150 } }
            onTextChanged: {
                opacity = 0.0
                textFadeIn.restart()
            }
            Timer {
                id: textFadeIn
                interval: 50
                onTriggered: cityNameText.opacity = 1.0
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                property real lastClick: 0
                onClicked: {
                    var now = Date.now()
                    if (now - lastClick < 400) {
                        lastClick = 0
                        if (page.focusId)
                            page.navigateToDetail(page.focusId)
                    } else {
                        lastClick = now
                    }
                }
            }
        }

        // [EN] Current weather text & temp display / [CN] 当前天气描述与温度显示
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                let w = page.weathers[page.focusId]
                if (!w) return ""
                return (w.text || "") + "  " + (w.temp || "--") + "°"
            }
            color: "white"; font.pixelSize: 28
        }

        // [EN] Row of city cards (excluding focus city) / [CN] 城市卡片行（排除焦点城市）
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            Repeater {
                model: page.cityList.slice(1)
                delegate: CityCard {
                    cityName: modelData.name
                    cityId: modelData.id
                    isFocus: modelData.id === page.focusId
                    weatherData: page.weathers[modelData.id] || ({})
                    onClicked: function(cityId) { page.focusRequested(cityId) }
                    onDoubleClicked: function(cityId) { page.navigateToDetail(cityId) }
                    onCloseClicked: function(cityId) { page.closeRequested(cityId) }
                }
            }
        }
    }
}
