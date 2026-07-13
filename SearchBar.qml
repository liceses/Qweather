import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 240; height: 40
    radius: 20
    color: "#30ffffff"
    border.width: 1
    border.color: "#40ffffff"

    property var cityList: []
    signal citySelected(string cityId)
    property alias placeholderText: placeholderLabel.text
    property bool loading: false

    // 最近一次发起搜索的文本，用于忽略过期网络响应
    property string _pendingSearch: ""

    Text {
        id: placeholderLabel
        anchors.centerIn: parent
        text: "搜索城市..."
        color: "#ccffffff"
        font.pixelSize: 14
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            searchPopup.open()
            input.forceActiveFocus()
        }
    }

    Popup {
        id: searchPopup
        x: -10; y: root.height + 6
        width: 320; height: 400
        padding: 12

        background: Rectangle {
            radius: 12
            color: "#f0f0f0"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // 搜索输入
            TextField {
                id: input
                Layout.fillWidth: true
                font.pixelSize: 16
                placeholderText: "输入城市名..."
                color: "#333"
                background: Rectangle {
                    radius: 8
                    color: "white"
                    border.width: 1
                    border.color: input.activeFocus ? "#4a90d9" : "#ddd"
                }

                onTextChanged: {
                    if (text.length >= 1) {
                        debounce.restart()
                    } else {
                        root.cityList = []
                        root.loading = false
                    }
                }

                // 回车键：停止防抖，立即重新搜索
                onAccepted: {
                    debounce.stop()
                    if (text.length >= 1) {
                        root.loading = true
                        root._pendingSearch = text
                        weatherApi.searchCity(text)
                    }
                }

                Keys.onEscapePressed: searchPopup.close()
            }

            // 结果列表
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.cityList

                // 空状态
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: resultList.count === 0 && !root.loading
                    Text {
                        anchors.centerIn: parent
                        text: input.length >= 1 ? "未找到匹配城市" : "输入城市名搜索"
                        color: "#999"
                        font.pixelSize: 13
                    }
                }

                // 加载中
                BusyIndicator {
                    anchors.centerIn: parent
                    visible: root.loading
                    running: root.loading
                }

                delegate: ItemDelegate {
                    width: resultList.width
                    height: 44
                    contentItem: Text {
                        text: modelData.name + "  " + modelData.adm1 + "  " + modelData.country
                        color: "#333"
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: index % 2 === 0 ? "#f8f8f8" : "white"
                        Rectangle {
                            anchors.fill: parent
                            color: "#e3f2fd"
                            opacity: parent.parent.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                    onClicked: {
                        root.citySelected(modelData.id)
                        placeholderLabel.text = modelData.name
                        searchPopup.close()
                    }
                }
            }
        }
    }

    // 防抖 —— 键入联想
    Timer {
        id: debounce
        interval: 300
        onTriggered: {
            if (input.length >= 1) {
                root.loading = true
                root._pendingSearch = input.text
                weatherApi.searchCity(input.text)
            }
        }
    }

    // 接收搜索结果 —— 忽略过期响应
    Connections {
        target: weatherApi
        function onCityLookupReady(citys) {
            if (root._pendingSearch !== input.text) return
            root.loading = false
            root.cityList = citys
        }
    }
}
