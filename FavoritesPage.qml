import QtQuick
import QtQuick.Controls

// 收藏页 —— 收藏城市列表，双击跳转详情
Item {
    id: page
    property var store: null

    Column {
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: page.store && page.store.trackedCities.length > 0 ? "已追踪城市" : "暂无城市"
            color: "white"
            font.pixelSize: 20
        }

        ListView {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400; height: 400
            model: page.store ? page.store.trackedCities : []
            delegate: ItemDelegate {
                width: 380; height: 48
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name + "  " + modelData.id
                    color: "white"
                    font.pixelSize: 16
                }
                onClicked: {
                    if (page.store) page.store.focusCityId = modelData.id
                    mainStack.currentIndex = 4  // 跳转城市详情
                }
            }
        }
    }
}
