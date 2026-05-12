import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

    property string editPortal:
        pluginApi?.pluginSettings?.portal ||
        pluginApi?.manifest?.metadata?.defaultSettings?.portal ||
        ""

    property string editGateway:
        pluginApi?.pluginSettings?.gateway ||
        pluginApi?.manifest?.metadata?.defaultSettings?.gateway ||
        ""

    property string editIface:
        pluginApi?.pluginSettings?.iface ||
        pluginApi?.manifest?.metadata?.defaultSettings?.iface ||
        "gpd0"

    property bool editDefaultRoute:
        pluginApi?.pluginSettings?.defaultRoute ??
        pluginApi?.manifest?.metadata?.defaultSettings?.defaultRoute ??
        false

    spacing: Style.marginM

    NText {
        text: "GlobalProtect VPN"
        font.pointSize: Style.fontSizeXL
        font.bold: true
    }

    NText {
        text: "Connection options for GlobalProtect VPN. Empty fields fall back to NOCTALIA_GPCLIENT_{PORTAL,GATEWAY,INTERFACE} env vars."
        color: Color.mSecondary
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "Connection"
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Portal"
        description: "GlobalProtect portal hostname (e.g. vpn.example.com)"
        placeholderText: "vpn.example.com"
        text: root.editPortal
        onTextChanged: root.editPortal = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Gateway"
        description: "Optional gateway override (-g flag). Leave empty for auto."
        placeholderText: ""
        text: root.editGateway
        onTextChanged: root.editGateway = text
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Interface"
        description: "Tunnel interface name"
        placeholderText: "gpd0"
        text: root.editIface
        onTextChanged: root.editIface = text
    }

    NDivider {
        Layout.fillWidth: true
        Layout.topMargin: Style.marginM
        Layout.bottomMargin: Style.marginM
    }

    NLabel {
        label: "Routing"
    }

    NToggle {
        Layout.fillWidth: true
        label: "Set default route via VPN"
        description: "Run `sudo ip route replace default dev <iface>` while connected; removed on disconnect."
        checked: root.editDefaultRoute
        onToggled: checked => root.editDefaultRoute = checked
    }

    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.portal = root.editPortal
        pluginApi.pluginSettings.gateway = root.editGateway
        pluginApi.pluginSettings.iface = root.editIface
        pluginApi.pluginSettings.defaultRoute = root.editDefaultRoute
        pluginApi.saveSettings()
    }
}
