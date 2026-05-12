import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    readonly property var geometryPlaceholder: panelContainer
    readonly property bool allowAttach: true

    readonly property var mainInstance: pluginApi?.mainInstance
    readonly property bool panelReady: pluginApi !== null && mainInstance !== null && mainInstance !== undefined

    property real contentPreferredWidth: panelReady ? 380 * Style.uiScaleRatio : 0
    property real contentPreferredHeight: panelReady ? 340 * Style.uiScaleRatio : 0

    anchors.fill: parent

    function statusLabel() {
        if (!mainInstance?.configured) return "Not configured"
        if (mainInstance?.connecting && !mainInstance?.connected) return "Connecting…"
        return mainInstance?.connected ? "Connected" : "Disconnected"
    }

    function statusColor() {
        if (!mainInstance?.configured) return Color.mOnSurfaceVariant
        if (mainInstance?.connecting && !mainInstance?.connected) return "#ffeb3b"
        return mainInstance?.connected ? "#4caf50" : Color.mOnSurfaceVariant
    }

    Rectangle {
        id: panelContainer
        anchors.fill: parent
        color: "transparent"
        visible: panelReady

        ColumnLayout {
            anchors {
                fill: parent
                margins: Style.marginM
            }
            spacing: Style.marginL

            NBox {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Style.marginM
                    spacing: Style.marginM

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NIcon {
                            icon: "shield"
                            pointSize: Style.fontSizeL
                            color: root.statusColor()
                        }

                        NText {
                            text: "GlobalProtect VPN"
                            pointSize: Style.fontSizeL
                            font.weight: Style.fontWeightBold
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        NText {
                            text: root.statusLabel()
                            pointSize: Style.fontSizeS
                            color: root.statusColor()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.alpha(Color.mOnSurface, 0.1)
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: Style.marginM
                        rowSpacing: Style.marginXS

                        NText {
                            text: "Interface"
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                        }
                        NText {
                            text: mainInstance?.iface || ""
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurface
                            font.family: Settings.data.ui.fontFixed
                            Layout.fillWidth: true
                        }

                        NText {
                            text: "Portal"
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                        }
                        NText {
                            text: mainInstance?.portal || "(unset)"
                            pointSize: Style.fontSizeS
                            color: mainInstance?.portal ? Color.mOnSurface : Color.mError
                            font.family: Settings.data.ui.fontFixed
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        NText {
                            text: "Gateway"
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurfaceVariant
                            visible: (mainInstance?.gateway || "") !== ""
                        }
                        NText {
                            text: mainInstance?.gateway || ""
                            pointSize: Style.fontSizeS
                            color: Color.mOnSurface
                            font.family: Settings.data.ui.fontFixed
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            visible: (mainInstance?.gateway || "") !== ""
                        }

                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Qt.alpha(Color.mOnSurface, 0.1)
                    }

                    NToggle {
                        Layout.fillWidth: true
                        label: "Default route via VPN"
                        description: "ip route add default dev " + (mainInstance?.iface || "")
                        checked: mainInstance?.defaultRoute ?? false
                        onToggled: function(value) {
                            if (!pluginApi) return
                            pluginApi.pluginSettings.defaultRoute = value
                            pluginApi.saveSettings()
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            NButton {
                Layout.fillWidth: true
                visible: (mainInstance?.connecting ?? false) && !(mainInstance?.connected ?? false)
                text: "Cancel connect"
                icon: "x"
                onClicked: mainInstance?.cancelConnect()
            }

            NButton {
                Layout.fillWidth: true
                visible: !(mainInstance?.connecting ?? false) || (mainInstance?.connected ?? false)
                text: (mainInstance?.connected ?? false) ? "Disconnect" : "Connect"
                icon: (mainInstance?.connected ?? false) ? "plug-x" : "plug"
                backgroundColor: (mainInstance?.connected ?? false) ? Color.mError : Color.mPrimary
                textColor: (mainInstance?.connected ?? false) ? Color.mOnError : Color.mOnPrimary
                enabled: mainInstance?.configured ?? false
                onClicked: {
                    if (!mainInstance) return
                    if (mainInstance.connected) {
                        mainInstance.disconnect()
                    } else {
                        mainInstance.connect()
                    }
                }
            }
        }
    }
}
