// InfoChip.qml — Small label-value chip for detail grid display
// 信息标签 — 详情网格中的小标签-值组件
import QtQuick

Rectangle {
    // [EN] Display label and value / [CN] 显示标签和值
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
