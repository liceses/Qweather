import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "logic.js" as Logic
ApplicationWindow{
    id: root
    width: 640
    height: 480
    visible: true
    title:qsTr("hello world!")
    Connections{
        target: weatherApi
        function onWeatherNowReady(now){
            console.log(Logic.stringify(now));
            cityTemp.text = now.temp
        }
        function onCityLookupReady(citys){
            searchBox.cityList = citys
        }
    }
    header: MenuBar{
        Menu{
            title: qsTr("&file")
            Action{
                text: qsTr("open")
                onTriggered: console.log("open some file")
            }
            MenuSeparator{}
            Action{
                text :qsTr("exit")
                onTriggered: Qt.quit()
            }
        }
        //content area


    }

    ComboBox{
        id: searchBox
        width: root.width/3
        editable: true
        property var cityList: []
        property string selectedCityid: ""
        model: cityList
        textRole: "name"
        onEditTextChanged: {
            debounce.restart()
        }
        onActivated: function(index){
            let city = cityList[index]
            selectedCityid = city.id;
            weatherApi.weatherNow(selectedCityid)
        }

        Timer{
            id: debounce
            interval: 300
            onTriggered: weatherApi.searchCity(searchBox.editText)
        }
    }

    Text {
        id: cityTemp
        text: qsTr("请搜索城市")
        anchors.left: searchBox.right
        anchors.leftMargin: 10
    }

}
