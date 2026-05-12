import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    readonly property var mainInstance: pluginApi?.mainInstance

    readonly property real contentWidth: Style.capsuleHeight
    readonly property real contentHeight: Style.capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Style.radiusL

        NIcon {
            id: vpnIcon
            anchors.centerIn: parent
            icon: "shield"
            pointSize: Style.fontSizeL
            applyUiScale: false
            color: {
                if (mouseArea.containsMouse) return Color.mOnHover
                if (mainInstance?.connected ?? false) return "#4caf50"
                if (mainInstance?.connecting ?? false) return "#ffeb3b"
                return Color.mOnSurface
            }

            SequentialAnimation on opacity {
                running: mainInstance?.connecting ?? false
                loops: Animation.Infinite
                alwaysRunToEnd: true

                NumberAnimation {
                    to: 0.25
                    duration: Style.animationSlowest
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    to: 1.0
                    duration: Style.animationSlowest
                    easing.type: Easing.InQuad
                }
            }
        }
    }

    NPopupContextMenu {
        id: contextMenu

        model: [
            {
                "label": (mainInstance?.connected ?? false) ? "Disconnect" : "Connect",
                "action": "toggle",
                "icon": (mainInstance?.connected ?? false) ? "plug-x" : "plug",
                "enabled": mainInstance?.configured ?? false,
                "visible": !(mainInstance?.connecting ?? false) || (mainInstance?.connected ?? false)
            },
            {
                "label": "Cancel connect",
                "action": "cancel",
                "icon": "x",
                "visible": (mainInstance?.connecting ?? false) && !(mainInstance?.connected ?? false)
            },
            {
                "label": "Widget settings",
                "action": "widget-settings",
                "icon": "settings"
            }
        ]

        onTriggered: action => {
            contextMenu.close()
            PanelService.closeContextMenu(screen)

            if (action === "widget-settings") {
                BarService.openPluginSettings(screen, pluginApi.manifest)
            } else if (action === "toggle") {
                if (!mainInstance) return
                if (mainInstance.connected) {
                    mainInstance.disconnect()
                } else {
                    mainInstance.connect()
                }
            } else if (action === "cancel") {
                mainInstance?.cancelConnect()
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            let msg
            if (!(mainInstance?.configured ?? false)) {
                msg = "VPN not configured • Set NOCTALIA_GPCLIENT_PORTAL"
            } else if (mainInstance?.connected ?? false) {
                msg = "Connected • Click for details"
            } else if (mainInstance?.connecting ?? false) {
                msg = "Connecting • Right-click to cancel"
            } else {
                msg = "Disconnected • Click for details"
            }
            TooltipService.show(root, msg, BarService.getTooltipDirection())
        }
        onExited: TooltipService.hide()

        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                PanelService.showContextMenu(contextMenu, root, screen)
            } else {
                if (pluginApi) {
                    pluginApi.openPanel(root.screen, root)
                }
            }
        }
    }
}
