import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// 收藏页 —— 收藏城市卡片列表，支持固定到侧边栏
// 外部注入：favorites, pinned, weathers, onCityClicked, onPinToggled, onCityDoubleClicked
Item {
    id: page

    property var favorites: []          // [{name, id, lat, lon}]
    property var pinned: []             // 已固定城市（用于判断状态）
    property var weathers: ({})         // { cityId: {temp, icon, text} }

    signal cityClicked(string cityId)
    signal cityDoubleClicked(string cityId)
    signal pinToggled(var cityObj)

    Flickable {
        anchors.fill: parent
        anchors.margins: 40
        clip: true
        contentHeight: contentColumn.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: contentColumn
            width: parent.width
            spacing: 12

            // 标题
            Text {
                text: "收藏城市"
                color: "white"
                font.pixelSize: 28
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // 空状态
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "暂无收藏城市\n在城市详情页点击星标即可收藏"
                color: "#60ffffff"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.6
                visible: page.favorites.length === 0
                Layout.topMargin: 60
            }

            // 收藏列表
            Repeater {
                model: page.favorites
                delegate: Rectangle {
                    id: card
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 12
                    color: hoverArea.containsMouse ? "#25ffffff" : "#20ffffff"
                    border.width: 1
                    border.color: hoverArea.containsMouse ? "#50ffffff" : "#30ffffff"

                    Behavior on color { ColorAnimation { duration: 200 } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    property var wdata: page.weathers[modelData.id] || ({})
                    property bool isPinned: {
                        let p = page.pinned
                        for (let i = 0; i < p.length; i++) {
                            if (p[i].id === modelData.id) return true
                        }
                        return false
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // 天气图标
                        WeatherIcon {
                            code: card.wdata.icon || "100"
                            iconSize: 36
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // 城市信息
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                text: modelData.name || modelData.id
                                color: "white"
                                font.pixelSize: 16
                                font.bold: true
                            }
                            Text {
                                text: card.wdata.text || ""
                                color: "#80ffffff"
                                font.pixelSize: 12
                                visible: text !== ""
                            }
                        }

                        // 温度
                        Text {
                            text: card.wdata.temp ? card.wdata.temp + "°" : "--°"
                            color: "white"
                            font.pixelSize: 22
                            font.bold: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // 固定按钮
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 32; height: 32
                            radius: 8
                            color: pinMouse.containsMouse ? "#35000000" : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: card.isPinned ? "📌" : "📍"
                                font.pixelSize: 14
                                color: card.isPinned ? "#4caf50" : "#80ffffff"
                            }

                            MouseArea {
                                id: pinMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.pinToggled(modelData)
                            }
                        }
                    }

                    // 点击/双击
                    property var _lastClick: 0
                    Timer {
                        id: clickTimer
                        interval: 400
                        onTriggered: {
                            page.cityClicked(modelData.id)
                            card._lastClick = 0
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        // 让 pin 按钮的 MouseArea 优先
                        z: -1

                        onClicked: function(mouse) {
                            var now = Date.now()
                            if (now - card._lastClick < 400) {
                                clickTimer.stop()
                                card._lastClick = 0
                                page.cityDoubleClicked(modelData.id)
                            } else {
                                card._lastClick = now
                                clickTimer.restart()
                            }
                        }
                    }
                }
            }

            // 底部留白
            Item { Layout.preferredHeight: 16; visible: page.favorites.length > 0 }
        }
    }
}
