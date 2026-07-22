// ApiUsagePage.qml — API endpoint request counters / API 端点请求次数统计
import QtQuick
import QtQuick.Layouts

Item {
    id: page

    // Raw data from C++, refreshed by Timer / 来自 C++ 的原始数据，由 Timer 刷新
    property var rawCounts: ({})

    // Convert to array of {key, requests, cacheHits, hitRate} for Repeater / 转为数组供 Repeater 使用
    property var countList: {
        var arr = []
        for (var k in rawCounts) {
            var v = rawCounts[k]
            var req = v.requests || 0
            var hit = v.cacheHits || 0
            arr.push({key: k, requests: req, cacheHits: hit, hitRate: req > 0 ? (hit / req * 100).toFixed(1) : "-"})
        }
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

            Grid {
                id: grid
                Layout.fillWidth: true
                columns: 2
                spacing: 8

                Repeater {
                    model: page.countList

                    Rectangle {
                        width: (grid.width - grid.spacing) / 2
                        height: 56; radius: 8
                        color: "#20ffffff"
                        border.width: 1; border.color: "#30ffffff"

                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 2
                            Text {
                                text: modelData.key
                                color: "white"; font.pixelSize: 12; font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                text: "请求: " + modelData.requests + "  缓存: " + modelData.cacheHits
                                color: "#ccffffff"; font.pixelSize: 11
                            }
                            Text {
                                text: "命中率: " + modelData.hitRate + "%"
                                color: modelData.hitRate !== "-" && parseFloat(modelData.hitRate) > 50 ? "#4caf50" : "#aaa"
                                font.pixelSize: 11; font.bold: true
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                Rectangle {
                    radius: 8
                    color: resetBtn.containsMouse ? "#30ffffff" : "#15ffffff"
                    border.width: 1; border.color: resetBtn.containsMouse ? "#50ffffff" : "#30ffffff"
                    Layout.preferredWidth: resetText.implicitWidth + 24
                    Layout.preferredHeight: 32
                    Text {
                        id: resetText; anchors.centerIn: parent
                        text: "重置计数"; color: "white"; font.pixelSize: 12
                    }
                    MouseArea {
                        id: resetBtn; anchors.fill: parent
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (weatherApi) weatherApi.resetCounts()
                            rawCounts = weatherApi ? weatherApi.requestCounts() : ({})
                        }
                    }
                }
            }

            Item { Layout.preferredHeight: 8 }
        }
    }
}
