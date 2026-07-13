import QtQuick
import QtQuick.Controls

ComboBox {
    id: searchBox
    width: 280
    editable: true

    property var cityList: []
    property string selectedCityId: ""

    model: cityList
    textRole: "name"

    // 下拉项
    delegate: ItemDelegate {
        width: searchBox.width
        text: modelData.name + " - " + modelData.adm1
        highlighted: searchBox.highlightedIndex === index
    }

    // 输入防抖
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
        onTriggered: weatherApi.searchCity(searchBox.editText)
    }
}
