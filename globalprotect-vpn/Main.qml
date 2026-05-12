import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null

    property string portal: Quickshell.env("NOCTALIA_GPCLIENT_PORTAL") ?? ""
    property string gateway: Quickshell.env("NOCTALIA_GPCLIENT_GATEWAY") ?? ""
    property string iface: Quickshell.env("NOCTALIA_GPCLIENT_INTERFACE") ?? "gpd0"
    property bool configured: root.portal !== ""
    property string gatewayArg: root.gateway !== "" ? " -g " + root.gateway : ""

    property bool connected: false
    property bool connecting: false

    readonly property bool defaultRoute:
        pluginApi?.pluginSettings?.defaultRoute ??
        pluginApi?.manifest?.metadata?.defaultSettings?.defaultRoute ??
        false

    // Last desired state — used to detect off-transition and remove the route
    property bool _lastShouldHave: false

    onConnectedChanged: {
        reconcileDefaultRoute()
        if (root.connected) {
            postConnectReconcile.restart()
        }
    }
    onDefaultRouteChanged: reconcileDefaultRoute()

    // gpclient may rewrite the routing table for several seconds after the
    // tunnel comes up. Burst-reconcile for ~15s post-connect.
    Timer {
        id: postConnectReconcile
        interval: 1000
        repeat: true
        property int ticksLeft: 0
        onTriggered: {
            reconcileDefaultRoute()
            ticksLeft--
            if (ticksLeft <= 0) stop()
        }
        function restart() {
            ticksLeft = 15
            start()
        }
    }

    // Idempotent reconcile: ensures `default dev <iface>` is present while
    // connected && defaultRoute, otherwise removes it. Called on state changes
    // AND every status poll, because gpclient may reset the routing table
    // after the tunnel comes up.
    function reconcileDefaultRoute() {
        if (!root.iface) return
        var shouldHave = root.connected && root.defaultRoute
        if (shouldHave) {
            ensureRouteProc.command = ["sh", "-c",
                "ip route show default | grep -qE 'default dev " + root.iface + "( |$)' || sudo ip route replace default dev " + root.iface]
            ensureRouteProc.running = true
        } else if (root._lastShouldHave) {
            delDefaultRouteProc.command = ["sh", "-c",
                "sudo ip route del default dev " + root.iface + " 2>/dev/null; true"]
            delDefaultRouteProc.running = true
        }
        root._lastShouldHave = shouldHave
    }

    function connect() {
        if (!root.configured) return
        if (root.connected || root.connecting) return
        root.connecting = true
        connectProc.running = true
    }

    function disconnect() {
        if (root.connected) {
            disconnectProc.running = true
        }
    }

    function cancelConnect() {
        if (root.connecting && !root.connected) {
            killConnectProc.running = true
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
            // Reconcile every poll so gpclient route changes get fixed up
            reconcileDefaultRoute()
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

    Process { id: ensureRouteProc }
    Process { id: delDefaultRouteProc }
}
