import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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

    property bool connected: false
    property bool connecting: false

    property string portal: Quickshell.env("NOCTALIA_GPCLIENT_PORTAL") ?? ""
    property string gateway: Quickshell.env("NOCTALIA_GPCLIENT_GATEWAY") ?? ""
    property string iface: Quickshell.env("NOCTALIA_GPCLIENT_INTERFACE") ?? "gpd0"
    property bool configured: root.portal !== ""
    property string gatewayArg: root.gateway !== "" ? " -g " + root.gateway : ""

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
                if (root.connected) return "#4caf50"
                if (root.connecting) return "#ffeb3b"
                return mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
            }

            SequentialAnimation on opacity {
                running: root.connecting
                loops: Animation.Infinite
                alwaysRunToEnd: true

                NumberAnimation {
                    to: 0.25
                    duration: Style.animationNormal
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    to: 1.0
                    duration: Style.animationNormal
                    easing.type: Easing.InQuad
                }
            }
        }
    }

    // Poll for tunnel interface status
    Timer {
        interval: root.connecting ? 500 : 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkStatus.running = true
    }

    Process {
        id: checkStatus
        command: ["sh", "-c", "ip link show " + root.iface + " 2>/dev/null | grep -q ',UP,'"]
        onExited: function(exitCode, exitStatus) {
            root.connected = (exitCode === 0)
            if (root.connected) {
                root.connecting = false
            }
        }
    }

    Process {
        id: connectProc
        command: ["sh", "-c", "sudo -E gpclient connect " + root.portal + root.gatewayArg + " --default-browser -i " + root.iface]
        onExited: function(exitCode, exitStatus) {
            // gpclient exited without bringing iface up → auth failed or aborted
            if (!root.connected) {
                root.connecting = false
            }
        }
    }

    Process {
        id: disconnectProc
        command: ["sh", "-c", "sudo -E gpclient disconnect"]
        onExited: function(exitCode, exitStatus) {
            root.connecting = false
            root.connected = false
        }
    }

    // Kill any in-flight `gpclient connect` (incl. its sudo wrapper) when
    // the user cancels mid-connect. `gpclient disconnect` only tears down
    // an established session and leaves the connect process running.
    Process {
        id: killConnectProc
        command: ["sh", "-c", "sudo pkill -TERM -f 'gpclient connect' 2>/dev/null; true"]
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            let msg
            if (!root.configured) {
                msg = "VPN not configured • Set NOCTALIA_GPCLIENT_PORTAL"
            } else if (root.connected) {
                msg = "Connected • Right-click to disconnect"
            } else if (root.connecting) {
                msg = "Connecting • Right-click to cancel"
            } else {
                msg = "Disconnected • Click to connect"
            }
            TooltipService.show(root, msg, BarService.getTooltipDirection())
        }
        onExited: TooltipService.hide()

        onClicked: function(mouse) {
            if (!root.configured) return
            if (mouse.button === Qt.RightButton) {
                if (root.connecting && !root.connected) {
                    killConnectProc.running = true
                } else if (root.connected) {
                    disconnectProc.running = true
                }
            } else {
                if (!root.connected && !root.connecting) {
                    root.connecting = true
                    connectProc.running = true
                }
            }
        }
    }
}
