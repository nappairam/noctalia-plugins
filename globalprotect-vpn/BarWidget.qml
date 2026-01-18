import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    property bool connected: false
    property bool connecting: false

    property string portal: Quickshell.env("NOCTALIA_GPCLIENT_PORTAL") ?? ""
    property string gateway: Quickshell.env("NOCTALIA_GPCLIENT_GATEWAY") ?? ""
    property string iface: Quickshell.env("NOCTALIA_GPCLIENT_INTERFACE") ?? "gpd0"
    property bool configured: root.portal !== ""
    property string gatewayArg: root.gateway !== "" ? " -g " + root.gateway : ""

    implicitWidth: vpnIcon.implicitWidth + Style.marginS * 2
    implicitHeight: vpnIcon.implicitHeight + Style.marginS * 2
    color: Style.capsuleColor
    radius: Style.radiusM
    opacity: (root.connected || root.connecting) ? 1.0 : 0.4

    NIcon {
        id: vpnIcon
        anchors.centerIn: parent
        icon: "shield"
        color: Color.mOnSurfaceVariant
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
                vpnIcon.color = "#4caf50"
            } else if (!root.connecting) {
                vpnIcon.color = Color.mOnSurfaceVariant
            }
        }
    }

    Process {
        id: connectProc
        command: ["sh", "-c", "sudo -E gpclient connect " + root.portal + root.gatewayArg + " --default-browser -i " + root.iface]
    }

    Process {
        id: disconnectProc
        command: ["sh", "-c", "sudo -E gpclient disconnect"]
    }

    MouseArea {
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
            } else {
                msg = "Disconnected • Click to connect"
            }
            TooltipService.show(root, msg, BarService.getTooltipDirection())
        }
        onExited: TooltipService.hide()

        onClicked: function(mouse) {
            if (!root.configured) return
            if (mouse.button === Qt.RightButton) {
                if (root.connected) {
                    disconnectProc.running = true
                }
            } else {
                if (!root.connected && !root.connecting) {
                    root.connecting = true
                    vpnIcon.color = "#ffeb3b"
                    connectProc.running = true
                }
            }
        }
    }
}
