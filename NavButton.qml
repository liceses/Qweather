import QtQuick
import QtQuick.Controls

// 导航按钮 —— 折叠态显示首字图标，展开态显示符号 + 文字
// active 绿色高亮，hover 白色高亮
Item {
    id: root
    property string label: ""
    property bool active: false
    property bool expanded: false
    signal clicked()

    implicitWidth: expanded ? 184 : 64
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: {
            if (root.active) return "#334caf50"
            if (mouseArea.containsMouse) return "#20ffffff"
            return "transparent"
        }
    }

    // 折叠态：首字图标居中
    Text {
        anchors.centerIn: parent
        text: root.label.charAt(0)
        color: root.active ? "#4caf50" : "#ccffffff"
        font.pixelSize: 16
        font.bold: true
        visible: !root.expanded
    }

    // 展开态：符号 + 文字
    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 8
        visible: root.expanded

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "●"
            color: root.active ? "#4caf50" : "#80ffffff"
            font.pixelSize: 8
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.active ? "#ffffff" : "#ccffffff"
            font.pixelSize: 13
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
