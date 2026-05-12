import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property var pluginApi: null

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
        text: "Connection options for GlobalProtect VPN."
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
        label: "Routing"
    }

    NToggle {
        Layout.fillWidth: true
        label: "Set default route via VPN"
        description: "Run `sudo ip route add default dev <iface>` while connected; removed on disconnect."
        checked: root.editDefaultRoute
        onToggled: checked => root.editDefaultRoute = checked
    }

    function saveSettings() {
        if (!pluginApi) return
        pluginApi.pluginSettings.defaultRoute = root.editDefaultRoute
        pluginApi.saveSettings()
    }
}
