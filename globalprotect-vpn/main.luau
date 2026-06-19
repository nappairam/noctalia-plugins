-- GlobalProtect VPN bar widget for Noctalia v5 (Luau plugin API).
--
-- Left click  : connect / disconnect
-- Right click : cancel an in-flight connect
--
-- Settings (declared in plugin.toml, read via barWidget.getConfig): portal,
-- gateway, iface, default_route. Empty text settings fall back to the
-- NOCTALIA_GPCLIENT_{PORTAL,GATEWAY,INTERFACE} environment variables.

-- ── tunables ────────────────────────────────────────────────────────────────
local POLL_IDLE_MS = 8000 -- steady-state status poll
local POLL_FAST_MS = 800 -- while connecting or just after connect
local CONNECT_TIMEOUT_TICKS = 56 -- ~45s at POLL_FAST_MS before giving up
local POST_CONNECT_TICKS = 20 -- ~16s of fast polling after the tunnel is up

-- ── state ─────────────────────────────────────────────────────────────────--
local connected = false
local connecting = false
local lastShouldHaveRoute = false
local connectingTicks = 0
local postConnectTicks = 0

-- ── settings helpers ──────────────────────────────────────────────────────--
local function settingStr(key, envName, default)
  local v = barWidget.getConfig(key)
  if v ~= nil and v ~= "" then
    return v
  end
  if envName then
    local e = noctalia.getenv(envName)
    if e ~= nil and e ~= "" then
      return e
    end
  end
  return default
end

local function portal()
  return settingStr("portal", "NOCTALIA_GPCLIENT_PORTAL", "")
end

local function gateway()
  return settingStr("gateway", "NOCTALIA_GPCLIENT_GATEWAY", "")
end

local function iface()
  return settingStr("iface", "NOCTALIA_GPCLIENT_INTERFACE", "gpd0")
end

local function defaultRoute()
  return barWidget.getConfig("default_route") == true
end

local function configured()
  return portal() ~= ""
end

-- ── presentation ──────────────────────────────────────────────────────────--
local function render()
  barWidget.setGlyph("shield")

  if connecting and not connected then
    barWidget.setGlyphColor("#ffeb3b", "script")
  elseif connected then
    barWidget.setGlyphColor("#4caf50", "script")
  else
    barWidget.setGlyphColor("on_surface", "auto")
  end

  local tip
  if not configured() then
    tip = { { "GlobalProtect", "Not configured" }, { "Hint", "Set the portal in widget settings" } }
  elseif connected then
    tip = { { "GlobalProtect", "Connected" }, { "Interface", iface() }, { "Portal", portal() } }
  elseif connecting then
    tip = { { "GlobalProtect", "Connecting..." }, { "Action", "Right-click to cancel" } }
  else
    tip = { { "GlobalProtect", "Disconnected" }, { "Action", "Click to connect" } }
  end
  barWidget.setTooltip(tip)

  barWidget.setVisible(true)
end

-- ── default route reconcile ───────────────────────────────────────────────--
-- gpclient may rewrite the routing table for several seconds after the tunnel
-- comes up, so this is called on every status poll, not just on transitions.
local function reconcileRoute()
  local i = iface()
  if i == "" then
    return
  end
  local shouldHave = connected and defaultRoute()
  if shouldHave then
    noctalia.runAsync(
      "ip route show default | grep -qE 'default dev " .. i .. "( |$)' || sudo ip route replace default dev " .. i
    )
  elseif lastShouldHaveRoute then
    noctalia.runAsync("sudo ip route del default dev " .. i .. " 2>/dev/null; true")
  end
  lastShouldHaveRoute = shouldHave
end

-- ── update interval management ────────────────────────────────────────────--
local function applyInterval()
  if (connecting and not connected) or postConnectTicks > 0 then
    noctalia.setUpdateInterval(POLL_FAST_MS)
  else
    noctalia.setUpdateInterval(POLL_IDLE_MS)
  end
end

-- ── status polling ────────────────────────────────────────────────────────--
local function checkStatus()
  local i = iface()
  noctalia.runAsync("ip link show " .. i .. " 2>/dev/null | grep -q ',UP,'", function(r)
    local wasConnected = connected
    connected = (r.exitCode == 0)

    if connected then
      connecting = false
      connectingTicks = 0
      if not wasConnected then
        postConnectTicks = POST_CONNECT_TICKS
      end
    end

    if connecting and not connected then
      connectingTicks = connectingTicks + 1
      if connectingTicks >= CONNECT_TIMEOUT_TICKS then
        connecting = false
        connectingTicks = 0
        noctalia.notifyError("GlobalProtect", "Connection timed out")
      end
    end

    if postConnectTicks > 0 then
      postConnectTicks = postConnectTicks - 1
    end

    reconcileRoute()
    applyInterval()
    render()
  end)
end

-- ── actions ───────────────────────────────────────────────────────────────--
local function startConnect()
  if not configured() then
    noctalia.notifyError("GlobalProtect", "Portal not configured")
    return
  end
  if connected or connecting then
    return
  end
  connecting = true
  connectingTicks = 0

  local cmd = "sudo -E gpclient connect " .. portal()
  if gateway() ~= "" then
    cmd = cmd .. " -g " .. gateway()
  end
  cmd = cmd .. " --default-browser -i " .. iface()

  -- gpclient connect stays alive for the lifetime of the tunnel, so it is
  -- launched detached; the status poll flips us to "connected" once the
  -- interface comes up.
  noctalia.runAsync(cmd)

  applyInterval()
  render()
end

local function startDisconnect()
  noctalia.runAsync("sudo -E gpclient disconnect", function()
    connected = false
    connecting = false
    connectingTicks = 0
    postConnectTicks = 0
    reconcileRoute()
    applyInterval()
    render()
  end)
end

local function cancelConnect()
  if not connecting or connected then
    return
  end
  noctalia.runAsync("sudo pkill -TERM -f 'gpclient connect' 2>/dev/null; true", function()
    connecting = false
    connectingTicks = 0
    applyInterval()
    render()
  end)
end

-- ── lifecycle callbacks ───────────────────────────────────────────────────--
function update()
  checkStatus()
end

function onClick()
  if connected then
    startDisconnect()
  else
    startConnect()
  end
end

function onRightClick()
  if connecting and not connected then
    cancelConnect()
  end
end

-- Initial paint + poll cadence (runs once when the script loads).
applyInterval()
render()
