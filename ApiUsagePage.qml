// ApiUsagePage.qml — API endpoint request counters / API 端点请求次数统计
import QtQuick
import QtQuick.Layouts

Item {
    id: page

    // Raw data from C++, refreshed by Timer / 来自 C++ 的原始数据，由 Timer 刷新
    property var rawCounts: ({})

    // Convert to array of {key, value} for Repeater / 转为 {key, value} 数组供 Repeater 使用
    property var countList: {
        var arr = []
        for (var k in rawCounts)
            arr.push({key: k, value: rawCounts[k]})
        return arr
    }

    // Refresh every 2 seconds / 每 2 秒刷新
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: rawCounts = weatherApi ? weatherApi.requestCounts() : ({})
    }

    Component.onCompleted: rawCounts = weatherApi ? weatherApi.requestCounts() : ({})

    Flickable {
        anchors.fill: parent; anchors.margins: 24
        contentHeight: content.implicitHeight + 32
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 16

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "API 请求统计"
                color: "white"
                font.pixelSize: 28; font.bold: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "本次会话累计（重启清零）"
                color: "#80ffffff"
                font.pixelSize: 13
            }

            Grid {
                id: grid
                Layout.fillWidth: true
                columns: 2
                spacing: 8

                Repeater {
                    model: page.countList

                    Rectangle {
                        width: (grid.width - grid.spacing) / 2
                        height: 44; radius: 8
                        color: "#20ffffff"
                        border.width: 1; border.color: "#30ffffff"

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 12
                            Text {
                                text: modelData.key
                                color: "#ccffffff"
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: modelData.value
                                color: "white"
                                font.pixelSize: 16; font.bold: true
                            }
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
