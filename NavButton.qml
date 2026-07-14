import QtQuick
import QtQuick.Controls
import QtQuick.Effects

// 导航按钮 —— 折叠态仅图标居中，展开态 icon + 文字左对齐
// active 绿色高亮，hover 白色高亮
// 图标着色：layer.effect MultiEffect brightness+colorization（Qt6 标准 SVG 染色方案）
Item {
    id: root
    property string label: ""
    property string icon: ""
    property bool active: false
    property bool expanded: false
    signal clicked()

    implicitWidth: expanded ? 184 : 64
    implicitHeight: 40

    Behavior on implicitWidth {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property real iconSize: root.expanded ? 18 : 24
    Behavior on iconSize {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    // 主题颜色
    readonly property bool _dark: appSettings ? appSettings.darkMode : true

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: {
            if (root.active) return "#334caf50"
            if (mouseArea.containsMouse) return "#20ffffff"
            return "transparent"
        }
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    // 折叠态：图标居中（展开时淡出）
    Image {
        anchors.centerIn: parent
        source: root.icon
        width: root.iconSize; height: root.iconSize
        sourceSize: Qt.size(24, 24)
        fillMode: Image.PreserveAspectFit
        opacity: root.expanded ? 0 : 1
        visible: opacity > 0
        layer.enabled: true
        layer.effect: MultiEffect {
            brightness: 1.0
            colorization: 1.0
            colorizationColor: root._dark ? "#1a1a1a" : (root.active ? "#ffffff" : "#ccffffff")
        }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    // 展开态：图标 + 文字左对齐（折叠时淡出）
    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 12
        spacing: 8
        opacity: root.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: root.icon
            width: root.iconSize; height: root.iconSize
            sourceSize: Qt.size(18, 18)
            fillMode: Image.PreserveAspectFit
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1.0
                colorization: 1.0
                colorizationColor: root._dark ? "#1a1a1a" : (root.active ? "#ffffff" : "#ccffffff")
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root._dark ? "#1a1a1a" : (root.active ? "#ffffff" : "#ccffffff")
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
