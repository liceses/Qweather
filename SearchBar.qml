import QtQuick
import QtQuick.Controls

// 自定义搜索框：半透明背景 + 白色文字
ComboBox {
    id: searchBox
    width: 280
    editable: true
    flat: true

    property var cityList: []
    property string selectedCityId: ""
    property var weatherApi: null    // 外部注入

    model: cityList
    textRole: "name"

    // 输入框背景
    background: Rectangle {
        radius: 8
        color: "#25000000"
        border.width: 1
        border.color: "#30ffffff"
    }

    // 输入区文字
    contentItem: TextField {
        anchors.fill: parent
        anchors.margins: 8
        color: "white"
        font.pixelSize: 14
        placeholderText: "搜索城市..."
        placeholderTextColor: "#80ffffff"
        background: Item {}
        verticalAlignment: Text.AlignVCenter
    }

    // 下拉项
    delegate: ItemDelegate {
        width: searchBox.width
        highlighted: searchBox.highlightedIndex === index
        contentItem: Text {
            text: modelData.name + " - " + modelData.adm1
            color: parent.highlighted ? "#4caf50" : "#333333"
            font.pixelSize: 14
        }
        background: Rectangle {
            color: parent.highlighted ? "#e8f5e9" : "transparent"
        }
    }

    onEditTextChanged: {
        if (editText.length >= 1) debounce.restart()
    }

    onActivated: function(index) {
        if (index >= 0 && index < cityList.length) {
            selectedCityId = cityList[index].id
            citySelected(selectedCityId)
        }
    }

    signal citySelected(string cityId)

    Timer {
        id: debounce
        interval: 300
        onTriggered: { if (searchBox.weatherApi) searchBox.weatherApi.searchCity(searchBox.editText) }
    }
}
