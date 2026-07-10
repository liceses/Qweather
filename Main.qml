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
    Button{
        id : but
        text: qsTr("click me to search")
        anchors.centerIn: parent
        width: root.width/5
        height: root.height/5
        visible: true
        onPressed: {
            root.title = qsTr("u clicked me");
            weatherApi.searchCity(cityInput.text);
            console.log("afterapicall")
        }
    }
    TextField{
        id:cityInput
        width:root.width/5
        height:root.height/5
        font.pointSize: 9
        placeholderText: qsTr("please input city name")
    }
    Connections{
        target: weatherApi
        function onWeatherNowReady(now){
            console.log(now);
        }
        function onCityLookupReady(citys){
            console.log(Logic.stringify(citys))
            

        }
    }
}
