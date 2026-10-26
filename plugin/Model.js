.pragma library

// Pure helpers for the network widget. Kept free of QML so they can be unit
// tested outside the shell.

var GLYPH_NETWORK = "\u{F04E2}"    // md-swap_vertical
var GLYPH_DOWN = "\u{F0045}"       // md-arrow_down
var GLYPH_UP = "\u{F005D}"         // md-arrow_up
var GLYPH_WIFI = "\u{F05A9}"       // md-wifi
var GLYPH_ETHERNET = "\u{F0200}"   // md-ethernet
var GLYPH_VPN = "\u{F0582}"        // md-vpn
var GLYPH_LAN = "\u{F0317}"        // md-lan
var GLYPH_SHIELD_OK = "\u{F0565}"  // md-shield_check
var GLYPH_SHIELD_WARN = "\u{F0ECC}" // md-shield_alert
var GLYPH_SHIELD_OFF = "\u{F099E}" // md-shield_off
var GLYPH_CONSOLE = "\u{F018D}"    // md-console
var GLYPH_OPEN = "\u{F03CC}"       // md-open_in_new
var GLYPH_BLOCK = "\u{F073A}"      // md-cancel
var GLYPH_ALLOW = "\u{F05E0}"      // md-check_circle
var GLYPH_RULES = "\u{F0279}"      // md-format_list_bulleted
var GLYPH_BACK = "\u{F004D}"       // md-arrow_left
var GLYPH_DELETE = "\u{F09E7}"     // md-delete_outline
var GLYPH_CHEVRON = "\u{F0142}"    // md-chevron_right
var GLYPH_APP = "\u{F0614}"        // md-application_outline
var GLYPH_SITE = "\u{F059F}"       // md-web
var GLYPH_ADDRESS = "\u{F0A60}"    // md-ip_network
var GLYPH_SYSTEM = "\u{F0493}"     // md-cog

// Written by install.sh: the root helper the widget runs through pkexec, and
// the summary of OpenSnitch rules + netwatch lists it keeps up to date.
var RULES_HELPER = "/usr/local/bin/netwatch-rules"
var RULES_EXPORT = "/run/netwatch/rules.json"

// A transfer counts as "active" above this many bytes per second, both ways.
var ACTIVE_RATE = 20 * 1000

var HISTORY = { day: 14, week: 8, month: 12 }
var GRANULARITIES = ["day", "week", "month"]
var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
var MONTHS_LONG = ["January", "February", "March", "April", "May", "June", "July", "August",
  "September", "October", "November", "December"]
var WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

// ---------- Formatting ----------

function formatBytes(bytes) {
  var value = Number(bytes) || 0
  var units = ["B", "kB", "MB", "GB", "TB", "PB"]
  var unit = 0
  while (Math.abs(value) >= 1000 && unit < units.length - 1) {
    value /= 1000
    unit++
  }
  if (unit === 0) return Math.round(value) + " B"
  return (value < 10 ? value.toFixed(1) : Math.round(value).toString()) + " " + units[unit]
}

function formatRate(bytesPerSecond) {
  var value = Math.max(0, Number(bytesPerSecond) || 0)
  if (value < 1000) return "0 B/s"
  return formatBytes(value) + "/s"
}

// Compact rate for the bar: "1.2M", "640K", "0K".
function formatRateShort(bytesPerSecond) {
  var value = Math.max(0, Number(bytesPerSecond) || 0)
  if (value < 1000) return "0K"
  var text = formatBytes(value)
  var parts = text.split(" ")
  return parts[0] + parts[1].charAt(0).toUpperCase()
}

// ---------- Live counters ----------

// /proc/net/dev -> { iface: { rx, tx } } in bytes.
function parseNetDev(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var colon = lines[i].indexOf(":")
    if (colon < 0) continue
    var name = lines[i].slice(0, colon).trim()
    var fields = lines[i].slice(colon + 1).trim().split(/\s+/)
    if (!name || fields.length < 9) continue
    out[name] = { rx: Number(fields[0]) || 0, tx: Number(fields[8]) || 0 }
  }
  return out
}

// Bytes/second per interface between two parseNetDev samples. A counter that
// went backwards (interface re-created) reads as idle rather than negative.
function ifaceRates(previous, current, seconds) {
  var out = {}
  if (!previous || !(seconds > 0)) return out
  for (var name in current) {
    var before = previous[name]
    if (!before) continue
    out[name] = {
      rx: Math.max(0, (current[name].rx - before.rx) / seconds),
      tx: Math.max(0, (current[name].tx - before.tx) / seconds)
    }
  }
  return out
}

function sumRates(rates, names) {
  var total = { rx: 0, tx: 0 }
  for (var i = 0; i < names.length; i++) {
    var r = rates[names[i]]
    if (!r) continue
    total.rx += r.rx
    total.tx += r.tx
  }
  return total
}

function pushSample(samples, value, limit) {
  var next = (samples || []).slice(Math.max(0, (samples || []).length - limit + 1))
  next.push(value)
  return next
}

// ---------- Interfaces ----------

// Lines of "name<TAB>physical<TAB>wireless<TAB>operstate" (see Panel.qml).
function parseInterfaces(text) {
  var out = []
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var f = lines[i].split("\t")
    if (f.length < 4 || !f[0] || f[0] === "lo") continue
    var physical = f[1] === "1"
    var wireless = f[2] === "1"
    out.push({
      name: f[0],
      physical: physical,
      wireless: wireless,
      up: f[3] === "up" || f[3] === "unknown",
      kind: interfaceKind(f[0], physical, wireless)
    })
  }
  return out
}

function interfaceKind(name, physical, wireless) {
  if (wireless) return "wifi"
  if (/^(tun|tap|wg|tailscale|zt|ppp|proton|nordlynx|mullvad)/.test(name)) return "vpn"
  if (/^ww/.test(name)) return "mobile"
  if (physical) return "ethernet"
  return "virtual"
}

function interfaceGlyph(kind) {
  if (kind === "wifi") return GLYPH_WIFI
  if (kind === "ethernet") return GLYPH_ETHERNET
  if (kind === "vpn") return GLYPH_VPN
  return GLYPH_LAN
}

function interfaceLabel(kind) {
  return ({ wifi: "Wi-Fi", ethernet: "Ethernet", vpn: "VPN", mobile: "Mobile", virtual: "Virtual" })[kind] || "Network"
}

// Interfaces whose traffic makes up the totals. VPN tunnels ride on a physical
// link, so counting both would double every byte; virtual bridges (docker,
// libvirt) are local. An explicit "a,b" setting overrides the choice.
function countedInterfaces(interfaces, setting) {
  var wanted = String(setting || "").split(",").map(function(s) { return s.trim() }).filter(Boolean)
  if (wanted.length > 0) return wanted
  return interfaces.filter(function(i) { return i.kind === "wifi" || i.kind === "ethernet" || i.kind === "mobile" })
    .map(function(i) { return i.name })
}

// ---------- vnstat history ----------

function pad2(n) { return (n < 10 ? "0" : "") + n }

function dayKey(y, m, d) { return y + "-" + pad2(m) + "-" + pad2(d) }

function monthKey(y, m) { return y + "-" + pad2(m) }

// Merge `vnstat --json d` and `vnstat --json m` output into
// { iface: { days: { "YYYY-MM-DD": {rx, tx} }, months: { "YYYY-MM": {rx, tx} } } }.
function parseVnstat(dayJson, monthJson) {
  var out = {}
  function ingest(json, table, keyOf, slot) {
    var ifaces = json && json.interfaces ? json.interfaces : []
    for (var i = 0; i < ifaces.length; i++) {
      var iface = ifaces[i]
      var rows = iface.traffic && iface.traffic[table] ? iface.traffic[table] : []
      var entry = out[iface.name] || (out[iface.name] = { days: {}, months: {} })
      for (var j = 0; j < rows.length; j++) {
        var d = rows[j].date || {}
        entry[slot][keyOf(d)] = { rx: Number(rows[j].rx) || 0, tx: Number(rows[j].tx) || 0 }
      }
    }
  }
  ingest(dayJson, "day", function(d) { return dayKey(d.year, d.month, d.day) }, "days")
  ingest(monthJson, "month", function(d) { return monthKey(d.year, d.month) }, "months")
  return out
}

function startOfDay(date) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function addDays(date, n) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() + n)
}

function mondayOf(date) {
  var day = startOfDay(date)
  return addDays(day, -((day.getDay() + 6) % 7))
}

// ISO 8601 week number.
function isoWeek(date) {
  var thursday = addDays(mondayOf(date), 3)
  var firstThursday = addDays(mondayOf(new Date(thursday.getFullYear(), 0, 4)), 3)
  return { year: thursday.getFullYear(), week: 1 + Math.round((thursday - firstThursday) / (7 * 86400000)) }
}

// The last N buckets of the given granularity, oldest first, each with totals
// for the counted interfaces and a per-interface breakdown of all of them.
function buckets(history, counted, granularity, now) {
  var count = HISTORY[granularity] || 14
  var today = startOfDay(now || new Date())
  var out = []
  for (var i = count - 1; i >= 0; i--) {
    var bucket
    if (granularity === "month") {
      var first = new Date(today.getFullYear(), today.getMonth() - i, 1)
      bucket = { key: monthKey(first.getFullYear(), first.getMonth() + 1), start: first,
        days: null, months: [monthKey(first.getFullYear(), first.getMonth() + 1)] }
    } else if (granularity === "week") {
      var monday = addDays(mondayOf(today), -7 * i)
      var w = isoWeek(monday)
      var days = []
      for (var d = 0; d < 7; d++) {
        var day = addDays(monday, d)
        days.push(dayKey(day.getFullYear(), day.getMonth() + 1, day.getDate()))
      }
      bucket = { key: w.year + "-W" + pad2(w.week), start: monday, week: w.week, days: days, months: null }
    } else {
      var date = addDays(today, -i)
      bucket = { key: dayKey(date.getFullYear(), date.getMonth() + 1, date.getDate()), start: date,
        days: [dayKey(date.getFullYear(), date.getMonth() + 1, date.getDate())], months: null }
    }
    fillBucket(bucket, history, counted)
    out.push(bucket)
  }
  return out
}

function fillBucket(bucket, history, counted) {
  bucket.rx = 0
  bucket.tx = 0
  bucket.interfaces = []
  var keys = bucket.days || bucket.months
  var slot = bucket.days ? "days" : "months"
  for (var name in history) {
    var rx = 0, tx = 0
    for (var k = 0; k < keys.length; k++) {
      var v = history[name][slot][keys[k]]
      if (v) { rx += v.rx; tx += v.tx }
    }
    if (rx + tx === 0) continue
    bucket.interfaces.push({ name: name, rx: rx, tx: tx, counted: counted.indexOf(name) !== -1 })
    if (counted.indexOf(name) !== -1) {
      bucket.rx += rx
      bucket.tx += tx
    }
  }
  bucket.interfaces.sort(function(a, b) { return (b.rx + b.tx) - (a.rx + a.tx) })
}

// Short axis label under a history bar.
function bucketLabel(bucket, granularity) {
  var s = bucket.start
  if (granularity === "month") return MONTHS[s.getMonth()]
  if (granularity === "week") return "W" + bucket.week
  return String(s.getDate())
}

// Heading for the selected bucket: "Today", "Last week", "September 2026"...
function bucketTitle(bucket, granularity, now) {
  var s = bucket.start
  var today = startOfDay(now || new Date())
  if (granularity === "month") {
    if (s.getFullYear() === today.getFullYear() && s.getMonth() === today.getMonth()) return "This month"
    return MONTHS_LONG[s.getMonth()] + " " + s.getFullYear()
  }
  if (granularity === "week") {
    var thisMonday = mondayOf(today)
    if (s.getTime() === thisMonday.getTime()) return "This week"
    if (s.getTime() === addDays(thisMonday, -7).getTime()) return "Last week"
    var end = addDays(s, 6)
    return MONTHS[s.getMonth()] + " " + s.getDate() + " – "
      + (end.getMonth() === s.getMonth() ? "" : MONTHS[end.getMonth()] + " ") + end.getDate()
  }
  if (s.getTime() === today.getTime()) return "Today"
  if (s.getTime() === addDays(today, -1).getTime()) return "Yesterday"
  return WEEKDAYS[s.getDay()] + ", " + MONTHS[s.getMonth()] + " " + s.getDate()
}

// Total over `count` days starting at `first`, for the counted interfaces.
// null when vnstat has no record of any of those days (e.g. before install).
function sumDays(history, counted, first, count) {
  var total = 0, seen = false
  for (var i = 0; i < count; i++) {
    var day = addDays(first, i)
    var key = dayKey(day.getFullYear(), day.getMonth() + 1, day.getDate())
    for (var c = 0; c < counted.length; c++) {
      var entry = history[counted[c]]
      var v = entry ? entry.days[key] : null
      if (v) { total += v.rx + v.tx; seen = true }
    }
  }
  return seen ? total : null
}

function percentChange(current, previous, against) {
  if (!(previous > 0)) return ""
  var pct = Math.round((current - previous) / previous * 100)
  if (pct === 0) return "Same as " + against
  return (pct > 0 ? "+" : "−") + Math.abs(pct) + "% vs " + against
}

// Comparison line under the selected period. Finished periods are compared
// with the one before; the period in progress is compared with the same
// stretch of the previous one, so a week isn't judged on its first two days.
function changeText(buckets, index, granularity, history, counted, now) {
  if (index <= 0 || index >= buckets.length) return ""
  var current = buckets[index].rx + buckets[index].tx
  if (index < buckets.length - 1) {
    var against = ({ day: "the day before", week: "the week before", month: "the month before" })[granularity]
    return percentChange(current, buckets[index - 1].rx + buckets[index - 1].tx, against)
  }

  var today = startOfDay(now || new Date())
  if (granularity === "day") {
    var yesterday = buckets[index - 1].rx + buckets[index - 1].tx
    return yesterday > 0 ? "Yesterday: " + formatBytes(yesterday) : ""
  }
  if (granularity === "week") {
    var monday = mondayOf(today)
    var elapsed = Math.round((today - monday) / 86400000) + 1
    var thisWeek = sumDays(history || {}, counted || [], monday, elapsed)
    var lastWeek = sumDays(history || {}, counted || [], addDays(monday, -7), elapsed)
    return thisWeek === null || lastWeek === null ? "" : percentChange(thisWeek, lastWeek, "this point last week")
  }
  var first = new Date(today.getFullYear(), today.getMonth(), 1)
  var previousFirst = new Date(today.getFullYear(), today.getMonth() - 1, 1)
  var previousLength = new Date(today.getFullYear(), today.getMonth(), 0).getDate()
  var thisMonth = sumDays(history || {}, counted || [], first, today.getDate())
  var lastMonth = sumDays(history || {}, counted || [], previousFirst, Math.min(today.getDate(), previousLength))
  return thisMonth === null || lastMonth === null ? "" : percentChange(thisMonth, lastMonth, "this point last month")
}

function maxTotal(buckets) {
  var max = 0
  for (var i = 0; i < buckets.length; i++) max = Math.max(max, buckets[i].rx + buckets[i].tx)
  return max
}

// ---------- Services ----------

// key=value lines from the status probe in Panel.qml.
function parseStatus(text) {
  var kv = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var eq = lines[i].indexOf("=")
    if (eq > 0) kv[lines[i].slice(0, eq).trim()] = lines[i].slice(eq + 1).trim()
  }
  return {
    vnstat: kv.vnstat_bin === "1" ? (kv.vnstat || "inactive") : "missing",
    opensnitch: kv.opensnitch_bin === "1" ? (kv.opensnitchd || "inactive") : "missing",
    ui: kv.ui === "1",
    nethogs: kv.nethogs_bin === "1",
    rules: kv.rules === undefined ? -1 : Number(kv.rules),
    helper: kv.helper === "1"
  }
}

// What the firewall is doing right now, for the status row and the bar badge.
function firewallState(status) {
  if (!status || status.opensnitch === "missing")
    return { level: "missing", glyph: GLYPH_SHIELD_OFF, title: "Firewall not installed",
      detail: "Run ~/Work/netwatch/install.sh to add OpenSnitch" }
  if (status.opensnitch !== "active")
    return { level: "off", glyph: GLYPH_SHIELD_OFF, title: "Firewall stopped",
      detail: "opensnitchd is " + status.opensnitch + " — new connections aren't checked" }
  if (!status.ui)
    return { level: "paused", glyph: GLYPH_SHIELD_WARN, title: "Prompts paused",
      detail: "The OpenSnitch window isn't running, so new apps can't be approved" }
  // `rules` counts only the rules saved from your answers to prompts.
  var detail = "OpenSnitch is checking new connections"
  if (status.rules === 0) detail = "No answers saved yet — choose \"always\" in a prompt to keep one"
  else if (status.rules > 0) detail = status.rules + (status.rules === 1 ? " rule" : " rules") + " saved from your answers"
  return { level: "ok", glyph: GLYPH_SHIELD_OK, title: "Asking about new apps", detail: detail }
}

// ---------- Bar ----------

var LABEL_MODES = ["active", "always", "none"]

function nextLabelMode(mode) {
  var index = LABEL_MODES.indexOf(mode)
  return LABEL_MODES[(index + 1) % LABEL_MODES.length]
}

function barLabel(rate, mode, active) {
  if (mode === "none" || (mode === "active" && !active)) return ""
  return GLYPH_DOWN + formatRateShort(rate.rx) + " " + GLYPH_UP + formatRateShort(rate.tx)
}

// ---------- Allowed & blocked ----------

// netwatch's lists: who they apply to, and where "the other way" lives.
var LIST_META = {
  "block-domains": { kind: "site", action: "block", opposite: "allow-domains" },
  "allow-domains": { kind: "site", action: "allow", opposite: "block-domains" },
  "block-nets": { kind: "address", action: "block", opposite: "allow-nets" },
  "allow-nets": { kind: "address", action: "allow", opposite: "block-nets" }
}

var SECTIONS = [
  { kind: "app", title: "APPS" },
  { kind: "site", title: "SITES" },
  { kind: "address", title: "IP ADDRESSES & NETWORKS" },
  { kind: "other", title: "OTHER RULES" },
  { kind: "system", title: "SYSTEM SERVICES · SET UP BY NETWATCH" }
]

function basename(path) {
  var s = String(path || "")
  return s.slice(s.lastIndexOf("/") + 1) || s
}

function shorten(text, max) {
  var s = String(text || "")
  return s.length > max ? s.slice(0, max - 1) + "…" : s
}

// One OpenSnitch rule (from the export) as a row: what it applies to, what it
// does, and enough detail to recognise it.
function ruleItem(rule) {
  var op = rule.operator || {}
  var conditions = op.type === "list" && op.list && op.list.length ? op.list : [op]
  var app = "", appPath = "", dests = [], others = [], destKind = "site"
  for (var i = 0; i < conditions.length; i++) {
    var c = conditions[i] || {}
    var data = String(c.data === undefined || c.data === null ? "" : c.data)
    var pattern = c.type === "regexp" ? " (pattern)" : ""
    if (c.operand === "process.path") { app = basename(data) + pattern; appPath = data }
    else if (c.operand === "process.command") { app = app || shorten(data, 40) + pattern; appPath = appPath || data }
    else if (c.operand === "dest.host") dests.push(data + pattern)
    else if (c.operand === "dest.ip" || c.operand === "dest.network") { dests.push(data + pattern); destKind = "address" }
    else if (c.operand === "dest.port") others.push("port " + data)
    else if (c.operand === "user.id") others.push("user " + data)
    else if (c.operand === "protocol") others.push(data.toUpperCase())
    else if (c.operand) others.push(c.operand + (data ? " " + data : ""))
  }
  var system = /^002-netwatch-/.test(rule.file || "")
  var title = app || dests.join(", ") || others.join(" · ") || rule.name || rule.file
  var detail = []
  if (rule.enabled === false) detail.push("off")
  if (app && dests.length) detail.push("to " + dests.join(", "))
  if (others.length && title !== others.join(" · ")) detail.push(others.join(" · "))
  if (appPath && appPath !== title) detail.push(appPath)
  return {
    id: "rule:" + rule.file,
    source: "rule",
    file: rule.file,
    action: rule.action === "allow" ? "allow" : "block",
    enabled: rule.enabled !== false,
    kind: system ? "system" : app ? "app" : dests.length ? destKind : "other",
    title: title,
    detail: detail.join(" · ")
  }
}

function listItem(listId, entry) {
  var meta = LIST_META[listId]
  return {
    id: "list:" + listId + ":" + entry,
    source: "list",
    list: listId,
    action: meta.action,
    enabled: true,
    kind: meta.kind,
    title: entry,
    detail: meta.action === "block" ? "Blocked for every app" : "Allowed for every app, without asking"
  }
}

// The export written by netwatch-rules, or a marker when it's missing.
function parseRules(text) {
  var raw = String(text || "").trim()
  if (raw === "" || raw.indexOf("NETWATCH_NO_EXPORT") === 0) return { ok: false, items: [] }
  var data
  try {
    data = JSON.parse(raw)
  } catch (e) {
    return { ok: false, items: [] }
  }
  var items = []
  var rules = data.rules || []
  for (var i = 0; i < rules.length; i++) {
    // 000/001 rules are the lists themselves; their entries are listed below.
    if (rules[i].error || /^00[01]-netwatch-/.test(rules[i].file || "")) continue
    items.push(ruleItem(rules[i]))
  }
  var lists = data.lists || {}
  for (var id in LIST_META) {
    var entries = lists[id] || []
    for (var j = 0; j < entries.length; j++) items.push(listItem(id, entries[j]))
  }
  return { ok: true, items: items, generated: data.generated || "" }
}

function countItems(items) {
  var out = { all: items.length, allow: 0, block: 0 }
  for (var i = 0; i < items.length; i++) out[items[i].action]++
  return out
}

// filter: "all" | "allow" | "block"; query matches name or detail.
function filterItems(items, filter, query) {
  var q = String(query || "").trim().toLowerCase()
  return items.filter(function(item) {
    if (filter === "allow" || filter === "block") {
      if (item.action !== filter) return false
    }
    return !q || item.title.toLowerCase().indexOf(q) !== -1 || item.detail.toLowerCase().indexOf(q) !== -1
  })
}

// Rows grouped for display: blocked first, then by name.
function sectionItems(items) {
  var out = []
  for (var s = 0; s < SECTIONS.length; s++) {
    var group = items.filter(function(item) { return item.kind === SECTIONS[s].kind })
    if (group.length === 0) continue
    group.sort(function(a, b) {
      if (a.action !== b.action) return a.action === "block" ? -1 : 1
      return a.title.localeCompare(b.title)
    })
    out.push({ title: SECTIONS[s].title, kind: SECTIONS[s].kind, items: group })
  }
  return out
}

// Flat order of rows as shown, for keyboard navigation.
function flattenSections(sections) {
  var out = []
  for (var i = 0; i < sections.length; i++) out = out.concat(sections[i].items)
  return out
}

function itemGlyph(item) {
  if (item.kind === "app") return GLYPH_APP
  if (item.kind === "site") return GLYPH_SITE
  if (item.kind === "address") return GLYPH_ADDRESS
  if (item.kind === "system") return GLYPH_SYSTEM
  return GLYPH_RULES
}

// netwatch-rules arguments that turn an allowed row into a blocked one or back.
function flipArgs(item) {
  if (item.source === "rule") return ["set-action", item.file, item.action === "allow" ? "deny" : "allow"]
  return ["list-add", LIST_META[item.list].opposite, item.title]
}

function deleteArgs(item) {
  if (item.source === "rule") return ["delete", item.file]
  return ["list-remove", item.list, item.title]
}

var DOMAIN_RE = /^(?=.{1,253}$)(?:[a-z0-9_](?:[a-z0-9_-]{0,61}[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$/
var IPV4_RE = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(?:\/(\d{1,2}))?$/
var IPV6_RE = /^[0-9a-f:.]*:[0-9a-f:.]*(?:\/(\d{1,3}))?$/

// What the "add" field holds: a domain name or an IP/network. The helper
// re-checks everything; this is for an immediate hint while typing.
function classifyEntry(text) {
  var value = String(text || "").trim().toLowerCase().replace(/\.$/, "")
  if (value === "") return { ok: false, error: "" }
  if (value.indexOf("*") !== -1)
    return { ok: false, error: "Wildcards aren't supported — add each name you want covered" }
  var v4 = IPV4_RE.exec(value)
  if (v4) {
    for (var i = 1; i <= 4; i++) if (Number(v4[i]) > 255) return { ok: false, error: "Not a valid IP address" }
    if (v4[5] !== undefined && (Number(v4[5]) < 1 || Number(v4[5]) > 32))
      return { ok: false, error: "Network size must be /1 to /32" }
    return { ok: true, kind: "address", value: value }
  }
  var v6 = IPV6_RE.exec(value)
  if (v6) {
    if (v6[1] !== undefined && (Number(v6[1]) < 1 || Number(v6[1]) > 128))
      return { ok: false, error: "Network size must be /1 to /128" }
    return { ok: true, kind: "address", value: value }
  }
  if (DOMAIN_RE.test(value)) return { ok: true, kind: "site", value: value }
  return { ok: false, error: "Enter a domain like example.com, or an IP address or network" }
}

function addArgs(entry, action) {
  var list = (action === "block" ? "block-" : "allow-") + (entry.kind === "site" ? "domains" : "nets")
  return ["list-add", list, entry.value]
}

// User-facing outcome of a pkexec'd helper run.
function helperOutcome(exitCode, output) {
  var text = String(output || "").trim()
  if (exitCode === 0) return { ok: true, text: "" }
  if (exitCode === 126) return { ok: false, text: "Cancelled — nothing was changed" }
  if (exitCode === 127) return { ok: false, text: "Not authorized to change rules" }
  return { ok: false, text: text ? text.split("\n").pop() : "Couldn't save the change (exit " + exitCode + ")" }
}

// Splits "…output…\nNETWATCH_EXIT=<code>" from the helper wrapper.
function parseHelperRun(text) {
  var raw = String(text || "")
  var m = /NETWATCH_EXIT=(\d+)\s*$/.exec(raw)
  return { exitCode: m ? Number(m[1]) : 1, output: m ? raw.slice(0, m.index) : raw }
}
