import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidePanel
    color: "#1a000000"

    // 当前页面索引（外部绑定 StackLayout.currentIndex）
    property int currentPage: 0
    // 焦点城市名（城市分区显示用）
    property string focusCityName: "北京"
    // 是否展开
    property bool expanded: false

    signal pageChanged(int page)

    // 展开状态
    state: expanded ? "wide" : "narrow"
    states: [
        State {
            name: "narrow"
            PropertyChanges { target: sidePanel; implicitWidth: 80 }
        },
        State {
            name: "wide"
            PropertyChanges { target: sidePanel; implicitWidth: 200 }
        }
    ]
    transitions: Transition {
        NumberAnimation { property: "implicitWidth"; duration: 200; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        // Logo（点击展开/折叠）
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 48; height: 48
            radius: 12
            color: "#4caf50"
            Text {
                anchors.centerIn: parent
                text: sidePanel.expanded ? "天气" : "W"
                color: "white"
                font.pixelSize: sidePanel.expanded ? 14 : 24
                font.bold: true
            }
            MouseArea {
                anchors.fill: parent
                onClicked: sidePanel.expanded = !sidePanel.expanded
            }
        }

        Item { Layout.preferredHeight: 12 }

        // ===== 导航分区 =====
        Text {
            text: sidePanel.expanded ? "导航" : ""
            color: "#80ffffff"
            font.pixelSize: 11
            visible: sidePanel.expanded
        }

        Repeater {
            model: [
                { label: "仪表盘",   page: 0 },
                { label: "空气质量", page: 1 },
                { label: "天气预报", page: 2 },
                { label: "阳光天文", page: 3 }
            ]
            NavButton {
                Layout.alignment: Qt.AlignHCenter
                label: modelData.label
                expanded: sidePanel.expanded
                active: sidePanel.currentPage === modelData.page
                onClicked: sidePanel.pageChanged(modelData.page)
            }
        }

        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: 8; Layout.rightMargin: 8
            color: "#20ffffff"
        }

        // ===== 城市分区 =====
        Text {
            text: sidePanel.expanded ? "城市" : ""
            color: "#80ffffff"
            font.pixelSize: 11
            visible: sidePanel.expanded
        }

        NavButton {
            Layout.alignment: Qt.AlignHCenter
            label: sidePanel.focusCityName
            expanded: sidePanel.expanded
            active: sidePanel.currentPage === 4
            onClicked: sidePanel.pageChanged(4)
        }

        // 分隔线
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: 8; Layout.rightMargin: 8
            color: "#20ffffff"
        }

        // ===== 收藏分区 =====
        NavButton {
            Layout.alignment: Qt.AlignHCenter
            label: "收藏"
            expanded: sidePanel.expanded
            active: sidePanel.currentPage === 5
            onClicked: sidePanel.pageChanged(5)
        }

        Item { Layout.fillHeight: true }

        // ===== 设置 =====
        NavButton {
            Layout.alignment: Qt.AlignHCenter
            label: "设置"
            expanded: sidePanel.expanded
            active: sidePanel.currentPage === 6
            onClicked: sidePanel.pageChanged(6)
        }
    }
}
