// SearchBar.qml — City search bar with popup, autocomplete, keyboard navigation
// 搜索栏 — 城市搜索弹窗、自动补全、键盘导航
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: 240; height: 40
    radius: 20
    color: hoverArea.containsMouse ? "#40ffffff" : "#30ffffff"
    border.width: 1
    border.color: hoverArea.containsMouse ? "#50ffffff" : "#40ffffff"

    // [EN] Search result list, selection signal, loading state, keyboard selection index / [CN] 搜索结果列表、选中信号、加载状态、键盘选中索引
    property var cityList: []
    signal citySelected(string cityId, string cityName, string lat, string lon)
    property alias placeholderText: placeholderLabel.text
    property bool loading: false
    property string _pendingSearch: ""
    property int _selectedIndex: -1

    Behavior on color { ColorAnimation { duration: 200 } }
    Behavior on border.color { ColorAnimation { duration: 200 } }

    // [EN] Search icon + placeholder text / [CN] 搜索图标 + 占位文字
    Row {
        anchors.centerIn: parent
        spacing: 6
        Text {
            text: "\uD83D\uDD0D"
            font.pixelSize: 12
            color: "#aaffffff"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: placeholderLabel
            text: "搜索城市..."
            color: "#ccffffff"
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: {
            searchPopup.open()
            input.forceActiveFocus()
        }
    }

    // [EN] Search popup with animations / [CN] 搜索弹窗（含入场/出场动画）
    Popup {
        id: searchPopup
        x: -50; y: root.height + 8
        width: 400; height: 440
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { property: "y"; from: root.height + 0; to: root.height + 8; duration: 180; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 }
        }

        background: Rectangle {
            radius: 16
            color: "#e61e2a1e"
            border.width: 1
            border.color: "#25ffffff"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // [EN] Search input area / [CN] 搜索输入区
            Item {

                Layout.fillWidth: true
                Layout.preferredHeight: 60

                Text {
                    text: "\uD83D\uDD0D"
                    font.pixelSize: 13
                    color: "#60ffffff"
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2
                }

                TextField {
                    id: input
                    anchors.left: parent.left
                    anchors.leftMargin: 38
                    anchors.right: clearBtn.left
                    anchors.rightMargin: 8
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    font.pixelSize: 16
                    placeholderText: "  输入城市名搜索..."
                    color: "#ffffff"
                    placeholderTextColor: "#50ffffff"
                    verticalAlignment: TextInput.AlignVCenter

                    background: Rectangle {
                        radius: 10
                        color: "#0affffff"
                    }

                    onTextChanged: {
                        root._selectedIndex = -1
                        if (text.length >= 1) {
                            debounce.restart()
                        } else {
                            root.cityList = []
                            root.loading = false
                        }
                    }

                    onAccepted: {
                        if (root._selectedIndex >= 0 && root._selectedIndex < root.cityList.length) {
                            selectCity(root._selectedIndex)
                            return
                        }
                        debounce.stop()
                        if (text.length >= 1) {
                            root.loading = true
                            root._pendingSearch = text
                            weatherApi.searchCity(text)
                        }
                    }

                    Keys.onUpPressed: {
                        if (root.cityList.length === 0) return
                        root._selectedIndex = Math.max(0, root._selectedIndex - 1)
                        resultList.positionViewAtIndex(root._selectedIndex, ListView.Contain)
                    }
                    Keys.onDownPressed: {
                        if (root.cityList.length === 0) return
                        root._selectedIndex = Math.min(root.cityList.length - 1, root._selectedIndex + 1)
                        resultList.positionViewAtIndex(root._selectedIndex, ListView.Contain)
                    }
                }

                Rectangle {
                    id: clearBtn
                    width: 22; height: 22
                    radius: 11
                    color: clearMouse.containsMouse ? "#35ffffff" : "#18ffffff"
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -2
                    visible: input.length > 0

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\u2715"
                        color: "#aaffffff"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            input.clear()
                            root.cityList = []
                            root.loading = false
                            root._selectedIndex = -1
                        }
                    }
                }
            }

            // [EN] Divider / [CN] 分隔线
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                color: "#12ffffff"
            }

            // [EN] Search result list with keyboard navigation / [CN] 搜索结果列表（支持键盘导航）
            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: root.cityList
                topMargin: 6
                bottomMargin: 6

                Text {
                    anchors.centerIn: parent
                    text: input.length >= 1 ? "未找到匹配城市" : "输入城市名搜索"
                    color: "#40ffffff"
                    font.pixelSize: 13
                    visible: resultList.count === 0 && !root.loading
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    visible: root.loading
                    running: root.loading
                    width: 28; height: 28
                }

                delegate: ItemDelegate {
                    id: itemDelegate
                    width: resultList.width
                    height: 50
                    padding: 0

                    readonly property bool sel: index === root._selectedIndex

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 10

                        Rectangle {
                            width: 28; height: 28
                            radius: 14
                            color: "#12ffffff"
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                anchors.centerIn: parent
                                text: "\uD83D\uDCCD"
                                font.pixelSize: 11
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text: modelData.name || ""
                                color: itemDelegate.sel ? "#4caf50" : "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: {
                                    var p = []
                                    if (modelData.adm1) p.push(modelData.adm1)
                                    if (modelData.country) p.push(modelData.country)
                                    return p.join(" \u00B7 ")
                                }
                                color: "#60ffffff"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: !!(modelData.adm1 || modelData.country)
                            }
                        }

                        Text {
                            text: "\u21B5"
                            color: itemDelegate.sel ? "#4caf50" : "#20ffffff"
                            font.pixelSize: 14
                            Layout.alignment: Qt.AlignVCenter
                            visible: itemDelegate.hovered || itemDelegate.sel
                        }
                    }

                    background: Rectangle {
                        color: {
                            if (itemDelegate.sel) return "#254caf50"
                            if (itemDelegate.hovered) return "#12ffffff"
                            return "transparent"
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.right: parent.right
                            anchors.rightMargin: 18
                            anchors.bottom: parent.bottom
                            height: 1
                            color: "#08ffffff"
                            visible: index < resultList.count - 1
                        }
                    }

                    onClicked: selectCity(index)
                }
            }
        }
    }

    // [EN] Select a city from results, emit signal and close popup / [CN] 选中搜索结果，发射信号并关闭弹窗
    function selectCity(idx) {
        if (idx < 0 || idx >= root.cityList.length) return
        var c = root.cityList[idx]
        root.citySelected(c.id, c.name, c.lat || "", c.lon || "")
        placeholderLabel.text = c.name
        root._selectedIndex = -1
        searchPopup.close()
    }

    // [EN] Debounce timer — wait 300ms before searching / [CN] 防抖定时器 — 300ms 后发起搜索
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

    // [EN] Handle API search results / [CN] 处理 API 搜索返回结果
    Connections {
        target: weatherApi
        function onCityLookupReady(citys) {
            if (root._pendingSearch !== input.text) return
            root.loading = false
            root.cityList = citys
            root._selectedIndex = -1
        }
    }
}
