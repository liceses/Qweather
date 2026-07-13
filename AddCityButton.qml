import QtQuick

Rectangle {
    signal clicked()

    width: 160; height: 100
    radius: 12
    color: "#15000000"
    border.width: 1
    border.color: "#20ffffff"

    Text {
        anchors.centerIn: parent
        text: "+"
        color: "#80ffffff"
        font.pixelSize: 36
    }

    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
    }
}
