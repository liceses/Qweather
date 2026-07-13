import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string icon: ""
    property string label: ""
    property bool active: false
    signal clicked()

    width: 64; height: 56

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.active ? "#33ffffff" : "transparent"
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: root.icon !== "" ? "qrc:/icons/" + root.icon + ".svg" : ""
            width: 24; height: 24
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: root.active ? "#ffffff" : "#ccffffff"
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
