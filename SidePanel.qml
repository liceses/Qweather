import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidePanel
    color: "#1a000000"

    property int currentPage: 0
    signal pageChanged(int page)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Logo
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 48; height: 48
            radius: 12
            color: "#4a90d9"
            Text {
                anchors.centerIn: parent
                text: "W"
                color: "white"
                font.pixelSize: 24
                font.bold: true
            }
        }

        // 导航按钮
        NavButton {
            Layout.alignment: Qt.AlignHCenter
            label: "仪表盘"
            active: sidePanel.currentPage === 0
            onClicked: sidePanel.pageChanged(0)
        }

        NavButton {
            Layout.alignment: Qt.AlignHCenter
            label: "收藏"
            active: sidePanel.currentPage === 1
            onClicked: sidePanel.pageChanged(1)
        }

        // 弹性空白
        Item { Layout.fillHeight: true }

        // 设置按钮
        NavButton {
            Layout.alignment: Qt.AlignHCenter
            label: "设置"
            active: sidePanel.currentPage === 2
            onClicked: sidePanel.pageChanged(2)
        }
    }
}
