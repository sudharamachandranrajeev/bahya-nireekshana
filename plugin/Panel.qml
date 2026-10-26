import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Network usage bar widget: live download/upload speed in the bar, and a
// panel with usage history per connection (vnstat), live per-app usage
// (nethogs, in a terminal), OpenSnitch firewall status, and an "Allowed &
// blocked" page to review and change what may use the network.
//
// Everything here runs unprivileged: speeds come from /proc/net/dev, history
// from `vnstat --json`, rules from the summary netwatch-rules exports. Rule
// changes go through pkexec (Omarchy's polkit prompt); nethogs opens a
// terminal for sudo.
Panel {
  id: root
  moduleName: "rajeevrama.netwatch"
  ipcTarget: "rajeevrama.netwatch"

  readonly property string home: Quickshell.env("HOME")
  readonly property string installScript: home + "/Work/netwatch/install.sh"
  readonly property string labelMode: setting("label", "active")
  readonly property string interfaceSetting: setting("interfaces", "")
  readonly property bool firewallBadge: setting("firewallBadge", true) !== false
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(fg, 1.4)
  readonly property int historyLength: 60

  // Live
  property var interfaces: []
  property var previousNetDev: null
  property real previousNetDevAt: 0
  property var rates: ({})
  property var rate: ({ rx: 0, tx: 0 })
  property var rxHistory: []
  property var txHistory: []
  property real lastActiveAt: 0

  // History
  property var history: ({})
  property string vnstatState: "loading"  // loading | ok | empty | missing
  property string granularity: "day"
  property int selectedIndex: -1          // -1: the current period

  // Services
  property var status: Model.parseStatus("")

  // Keyboard cursor over the action rows in the panel.
  property int cursorIndex: -1

  // "Allowed & blocked" page
  property string page: "overview"        // overview | rules
  property var rules: Model.parseRules("")
  property bool rulesLoaded: false
  property string rulesFilter: "all"      // all | allow | block
  property string rulesQuery: ""
  property int ruleCursor: -1
  property string busyId: ""              // row being changed; "add" for the add field
  property var ruleNotice: ({ ok: true, text: "" })
  readonly property var ruleCounts: Model.countItems(rules.items)
  readonly property var ruleSections: Model.sectionItems(Model.filterItems(rules.items, rulesFilter, rulesQuery))
  readonly property var ruleRows: Model.flattenSections(ruleSections)

  readonly property var counted: Model.countedInterfaces(interfaces, interfaceSetting)
  readonly property bool active: rate.rx + rate.tx > Model.ACTIVE_RATE
  readonly property bool showActive: active || Date.now() - lastActiveAt < 4000
  readonly property var firewall: Model.firewallState(status)
  readonly property bool warnFirewall: firewallBadge
    && (firewall.level === "paused" || firewall.level === "off")
  readonly property var periodBuckets: Model.buckets(history, counted, granularity, new Date())
  readonly property int currentIndex: selectedIndex < 0 ? periodBuckets.length - 1 : selectedIndex
  readonly property var todayBucket: {
    var days = Model.buckets(history, counted, "day", new Date())
    return days[days.length - 1]
  }
  readonly property var primaryInterface: {
    for (var i = 0; i < interfaces.length; i++) {
      if (interfaces[i].up && counted.indexOf(interfaces[i].name) !== -1) return interfaces[i]
    }
    return null
  }
  readonly property var actions: {
    var out = [
      { id: "rules", glyph: Model.GLYPH_RULES, title: "Allowed & blocked", chevron: true,
        detail: status.opensnitch === "missing" ? "Needs OpenSnitch — run the setup script"
          : !status.helper ? "Run the setup script again to manage rules here"
          : rules.ok ? ruleCounts.allow + " allowed · " + ruleCounts.block + " blocked · review and change"
          : "Review and change what may use the network",
        enabled: status.opensnitch !== "missing" },
      { id: "nethogs", glyph: Model.GLYPH_CONSOLE, title: "Live usage by app",
        detail: status.nethogs ? "Opens nethogs in a terminal (asks for your password)" : "Needs nethogs — run the setup script",
        enabled: status.nethogs },
      { id: "firewall", glyph: Model.GLYPH_OPEN, title: "OpenSnitch window",
        detail: status.opensnitch === "missing" ? "Needs OpenSnitch — run the setup script"
          : "Connection log, statistics and time-limited answers",
        enabled: status.opensnitch !== "missing" }
    ]
    return out
  }

  function refreshInterfaces() { if (!ifaceProc.running) ifaceProc.running = true }
  function refreshStatus() { if (!statusProc.running) statusProc.running = true }
  function refreshHistory() { if (!vnstatProc.running) vnstatProc.running = true }
  function refreshRules() { if (!rulesProc.running) rulesProc.running = true }

  function refreshAll() {
    refreshInterfaces()
    refreshStatus()
    refreshHistory()
    refreshRules()
  }

  function applyNetDev(raw) {
    var sample = Model.parseNetDev(raw)
    var now = Date.now()
    if (previousNetDev) {
      rates = Model.ifaceRates(previousNetDev, sample, (now - previousNetDevAt) / 1000)
      rate = Model.sumRates(rates, counted)
      rxHistory = Model.pushSample(rxHistory, rate.rx, historyLength)
      txHistory = Model.pushSample(txHistory, rate.tx, historyLength)
      if (active) lastActiveAt = now
    }
    // An interface appearing (VPN up, cable plugged in) needs classifying.
    var names = Object.keys(sample).sort().join(",")
    if (previousNetDev && names !== Object.keys(previousNetDev).sort().join(",")) refreshInterfaces()
    previousNetDev = sample
    previousNetDevAt = now
  }

  function applyHistory(raw) {
    var text = String(raw || "")
    if (text.indexOf("NETWATCH_NO_VNSTAT") === 0) {
      vnstatState = "missing"
      return
    }
    var parts = text.split("\u001e")
    try {
      history = Model.parseVnstat(JSON.parse(parts[0] || "{}"), JSON.parse(parts[1] || "{}"))
      vnstatState = Object.keys(history).length > 0 ? "ok" : "empty"
    } catch (e) {
      // vnstat exits with an error until its daemon has saved the first sample.
      vnstatState = "empty"
    }
  }

  function setGranularity(value) {
    if (Model.GRANULARITIES.indexOf(value) === -1 || value === granularity) return
    granularity = value
    selectedIndex = -1
  }

  function moveSelection(delta) {
    var next = Math.max(0, Math.min(periodBuckets.length - 1, currentIndex + delta))
    selectedIndex = next === periodBuckets.length - 1 ? -1 : next
  }

  function terminal(command) {
    Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", command])
    close()
  }

  function runSetup() { terminal("sudo " + installScript) }

  function startFirewallWindow() {
    // A second opensnitch-ui hands over to a running one, which shows its window.
    Quickshell.execDetached(["setsid", "uwsm-app", "--", "opensnitch-ui"])
    statusRecheck.restart()
  }

  function runAction(action) {
    if (!action || !action.enabled) return
    if (action.id === "nethogs") terminal("sudo nethogs -C")
    else if (action.id === "firewall") {
      startFirewallWindow()
      close()
    } else if (action.id === "rules") {
      if (!status.helper) runSetup()
      else openRules()
    }
  }

  // ---------- Allowed & blocked ----------

  function openRules() {
    page = "rules"
    ruleCursor = -1
    ruleNotice = { ok: true, text: "" }
    refreshRules()
  }

  function closeRules() {
    page = "overview"
    rulesQuery = ""
  }

  function moveRuleCursor(delta) {
    if (ruleRows.length === 0) return
    if (ruleCursor < 0) ruleCursor = delta > 0 ? 0 : ruleRows.length - 1
    else ruleCursor = Math.max(0, Math.min(ruleRows.length - 1, ruleCursor + delta))
  }

  // Runs netwatch-rules through pkexec; Omarchy's polkit agent asks for the
  // password (then remembers it for a few minutes).
  function runHelper(id, args, doneText) {
    if (helperProc.running) return
    busyId = id
    ruleNotice = { ok: true, text: "Waiting for authentication…" }
    helperProc.doneText = doneText
    helperProc.command = ["sh", "-c", "pkexec \"$0\" \"$@\" 2>&1; echo \"NETWATCH_EXIT=$?\"", Model.RULES_HELPER].concat(args)
    helperProc.running = true
  }

  function flipRule(item) {
    if (!item) return
    var verb = item.action === "allow" ? "Blocked " : "Allowed "
    runHelper(item.id, Model.flipArgs(item), verb + item.title)
  }

  function deleteRule(item) {
    if (!item) return
    runHelper(item.id, Model.deleteArgs(item), "Removed " + item.title
      + (item.source === "rule" ? " — OpenSnitch will ask about it again" : ""))
  }

  function addEntry(text, action) {
    var entry = Model.classifyEntry(text)
    if (!entry.ok) {
      ruleNotice = { ok: false, text: entry.error || "Enter a domain or an IP address" }
      return false
    }
    runHelper("add", Model.addArgs(entry, action), (action === "block" ? "Blocked " : "Allowed ") + entry.value)
    return true
  }

  function applyHelperRun(raw) {
    var run = Model.parseHelperRun(raw)
    var outcome = Model.helperOutcome(run.exitCode, run.output)
    ruleNotice = outcome.ok ? { ok: true, text: helperProc.doneText } : outcome
    busyId = ""
    refreshRules()
    refreshStatus()
  }

  function moveCursor(delta) {
    if (actions.length === 0) return
    if (cursorIndex < 0) cursorIndex = delta > 0 ? 0 : actions.length - 1
    else cursorIndex = Math.max(0, Math.min(actions.length - 1, cursorIndex + delta))
  }

  function cycleLabel() {
    root.settings = Object.assign({}, root.settings, { label: Model.nextLabelMode(root.labelMode) })
    if (root.bar && root.bar.shell) root.bar.shell.updateEntryInline(root.moduleName, root.settings)
  }

  onOpenedChanged: {
    if (opened) {
      cursorIndex = -1
      selectedIndex = -1
      refreshAll()
    } else {
      closeRules()
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Component.onCompleted: {
    refreshAll()
    netDevProc.running = true
  }

  Process {
    id: netDevProc
    command: ["cat", "/proc/net/dev"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyNetDev(text) }
  }

  Process {
    id: ifaceProc
    command: ["sh", "-c",
      "for d in /sys/class/net/*; do n=${d##*/}; p=0; w=0;"
      + " [ -e \"$d/device\" ] && p=1;"
      + " { [ -e \"$d/wireless\" ] || [ -e \"$d/phy80211\" ]; } && w=1;"
      + " printf '%s\\t%s\\t%s\\t%s\\n' \"$n\" \"$p\" \"$w\" \"$(cat \"$d/operstate\" 2>/dev/null)\"; done"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.interfaces = Model.parseInterfaces(text) }
  }

  Process {
    id: vnstatProc
    command: ["sh", "-c",
      "command -v vnstat >/dev/null || { echo NETWATCH_NO_VNSTAT; exit 0; };"
      + " vnstat --json d 62 2>/dev/null; printf '\\036'; vnstat --json m 13 2>/dev/null; exit 0"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyHistory(text) }
  }

  Process {
    id: statusProc
    command: ["sh", "-c",
      "command -v vnstat >/dev/null && echo vnstat_bin=1;"
      + " command -v opensnitchd >/dev/null && echo opensnitch_bin=1;"
      + " command -v nethogs >/dev/null && echo nethogs_bin=1;"
      + " echo vnstat=$(systemctl is-active vnstat.service);"
      + " echo opensnitchd=$(systemctl is-active opensnitchd.service);"
      + " pgrep -x opensnitch-ui >/dev/null && echo ui=1;"
      + " r=/etc/opensnitchd/rules; [ -r $r ] && [ -x $r ] &&"
      + " echo rules=$(ls $r/*.json 2>/dev/null | grep -vc '/00[0-2]-netwatch-');"
      + " [ -x " + Model.RULES_HELPER + " ] && echo helper=1; exit 0"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.status = Model.parseStatus(text) }
  }

  Process {
    id: rulesProc
    command: ["sh", "-c", "cat " + Model.RULES_EXPORT + " 2>/dev/null || echo NETWATCH_NO_EXPORT"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.rules = Model.parseRules(text)
        root.rulesLoaded = true
        if (root.ruleCursor >= root.ruleRows.length) root.ruleCursor = root.ruleRows.length - 1
      }
    }
  }

  Process {
    id: helperProc
    property string doneText: ""
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.applyHelperRun(text) }
  }

  // Answers given in OpenSnitch prompts show up while the page is open.
  Timer {
    interval: 4000
    running: root.opened && root.page === "rules"
    repeat: true
    onTriggered: root.refreshRules()
  }

  // Speed: every second while the panel is open, every two otherwise.
  Timer {
    interval: root.opened ? 1000 : 2000
    running: true
    repeat: true
    onTriggered: if (!netDevProc.running) netDevProc.running = true
  }

  Timer {
    interval: root.opened ? 5000 : 30000
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    interval: root.opened ? 60000 : 300000
    running: true
    repeat: true
    onTriggered: {
      root.refreshHistory()
      root.refreshInterfaces()
    }
  }

  // The prompt window takes a moment to come up after a start.
  Timer {
    id: statusRecheck
    interval: 2500
    onTriggered: root.refreshStatus()
  }

  // ---------- Bar button ----------

  Row {
    id: button
    spacing: 0

    readonly property string label: Model.barLabel(root.rate, root.labelMode, root.showActive)
    readonly property string tooltip: Model.GLYPH_DOWN + " " + Model.formatRate(root.rate.rx) + "   "
      + Model.GLYPH_UP + " " + Model.formatRate(root.rate.tx)
      + (root.vnstatState === "ok" && root.todayBucket
        ? "\nToday " + Model.formatBytes(root.todayBucket.rx + root.todayBucket.tx) : "")
      + (root.status.opensnitch !== "missing" ? "\nFirewall: " + root.firewall.title : "")

    function press(b) {
      if (b === Qt.RightButton) root.cycleLabel()
      else if (b === Qt.MiddleButton) root.runAction(root.actions[0])
      else root.toggle()
    }

    BarIconButton {
      id: iconButton
      bar: root.bar
      tooltipText: button.tooltip
      onPressed: function(b) { button.press(b) }

      iconComponent: Item {
        OpticalGlyph {
          anchors.fill: parent
          text: Model.GLYPH_NETWORK
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          fontSize: Style.bar.iconFont
          color: root.showActive ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground)

          Behavior on color { ColorAnimation { duration: 260 } }
        }

        // Firewall isn't asking: OpenSnitch stopped or its window closed.
        Rectangle {
          width: Math.max(5, Style.space(5))
          height: width
          radius: width / 2
          anchors.right: parent.right
          anchors.top: parent.top
          color: Color.urgent
          visible: root.warnFirewall
        }
      }
    }

    WidgetButton {
      bar: root.bar
      visible: text !== "" && !iconButton.vertical
      text: button.label
      tooltipText: button.tooltip
      horizontalMargin: 2
      fontSize: Style.font.bodySmall
      onPressed: function(b) { button.press(b) }
    }

    Item {
      visible: button.label !== "" && !iconButton.vertical
      width: Style.space(6)
      height: 1
    }
  }

  // ---------- Panel ----------

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(root.page === "rules" ? rulesView.implicitHeight : column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      readonly property bool onRules: root.page === "rules"
      onMoveRequested: function(dx, dy) {
        if (onRules) {
          if (dy !== 0) root.moveRuleCursor(dy)
          else if (dx < 0) root.closeRules()
        } else if (dy !== 0) root.moveCursor(dy)
        else if (dx !== 0) root.moveSelection(dx)
      }
      onActivateRequested: {
        if (onRules) root.flipRule(root.ruleRows[root.ruleCursor])
        else root.runAction(root.actions[root.cursorIndex])
      }
      onDeleteRequested: if (onRules) root.deleteRule(root.ruleRows[root.ruleCursor])
      onCloseRequested: onRules ? root.closeRules() : root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r") root.refreshAll()
        else if (onRules) {
          if (t === "/") rulesView.focusSearch()
          else if (t === "a") rulesView.focusAdd()
          else if (t === "1") root.rulesFilter = "all"
          else if (t === "2") root.rulesFilter = "allow"
          else if (t === "3") root.rulesFilter = "block"
        }
        else if (t === "d") root.setGranularity("day")
        else if (t === "w") root.setGranularity("week")
        else if (t === "m") root.setGranularity("month")
      }

      Flickable {
        id: scroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: root.page === "rules" ? rulesView.implicitHeight : column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Connections {
          target: root
          function onPageChanged() { scroll.contentY = 0 }
        }

        NetContent {
          id: column
          width: scroll.width
          visible: root.page === "overview"
          panel: root
        }

        RulesContent {
          id: rulesView
          width: scroll.width
          visible: root.page === "rules"
          panel: root
        }
      }
    }
  }
}
