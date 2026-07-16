import QtQuick
import QtQuick.Layouts

// 仪表盘页 —— 从 Main.qml 提取的独立页面
// 数据由父级 Main.qml 通过属性注入，交互通过信号上报
Item {
    id: page

    // ===== 输入属性（Main.qml 绑定注入） =====
    property var cityList: []
    property string focusId: ""
    property string focusName: ""
    property var weathers: ({})

    // ===== 信号（上报给 Main.qml 处理） =====
    signal citySelected(string cityId, string cityName, string lat, string lon)
    signal focusRequested(string cityId)
    signal navigateToDetail(string cityId)
    signal closeRequested(string cityId)

    // ===== 辅助 =====
    // cityName 由 Main.qml 统一管理，通过 focusName 属性传入

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24

        SearchBar {
            id: searchBox
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 300
            onCitySelected: function(cityId, cityName, lat, lon) {
                page.citySelected(cityId, cityName, lat, lon)
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: page.focusName || "搜索城市开始"
            color: "white"; font.pixelSize: 48; font.bold: true
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                let w = page.weathers[page.focusId]
                if (!w) return ""
                return (w.text || "") + "  " + (w.temp || "--") + "°"
            }
            color: "white"; font.pixelSize: 28
        }

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
