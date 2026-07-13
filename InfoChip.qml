import QtQuick

Rectangle {
    property string label: ""
    property string value: "--"

    width: infoRow.width + 20; height: 36
    radius: 8
    color: "#20000000"

    Row {
        id: infoRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: parent.parent.label
            color: "#ccffffff"
            font.pixelSize: 12
        }
        Text {
            text: parent.parent.value
            color: "white"
            font.pixelSize: 14
            font.bold: true
        }
    }
}
