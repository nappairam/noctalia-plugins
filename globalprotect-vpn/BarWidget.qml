import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

NIconButton {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property real scaling: 1.0

    property bool connected: false
    property bool connecting: false

    property string portal: Quickshell.env("NOCTALIA_GPCLIENT_PORTAL") ?? ""
    property string gateway: Quickshell.env("NOCTALIA_GPCLIENT_GATEWAY") ?? ""
    property string iface: Quickshell.env("NOCTALIA_GPCLIENT_INTERFACE") ?? "gpd0"
    property bool configured: root.portal !== ""
    property string gatewayArg: root.gateway !== "" ? " -g " + root.gateway : ""

    baseSize: Style.capsuleHeight
    compact: (Settings.data.bar.density === "compact")
    icon: "shield"
    colorBg: Settings.data.bar.showCapsule ? Color.mSurfaceVariant : Color.transparent
    colorFg: root.connected ? "#4caf50" : (root.connecting ? "#ffeb3b" : Color.mOnSurfaceVariant)
    colorBorder: Color.transparent
    colorBorderHover: Color.transparent
    opacity: (root.connected || root.connecting) ? Style.opacityFull : Style.opacityMedium
    tooltipDirection: BarService.getTooltipDirection()
    tooltipText: !root.configured
        ? "VPN not configured • Set NOCTALIA_GPCLIENT_PORTAL"
        : (root.connected
            ? "Connected • Right-click to disconnect"
            : "Disconnected • Click to connect")

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
    }

    Process {
        id: disconnectProc
        command: ["sh", "-c", "sudo -E gpclient disconnect"]
    }

    onClicked: {
        if (!root.configured) return
        if (!root.connected && !root.connecting) {
            root.connecting = true
            connectProc.running = true
        }
    }

    onRightClicked: {
        if (!root.configured) return
        if (root.connected) {
            disconnectProc.running = true
        }
    }
}
