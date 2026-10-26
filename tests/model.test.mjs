// Unit tests for the widget's Model.js: node --test tests/
import { test } from "node:test"
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { homedir } from "node:os"
import vm from "node:vm"

const source = readFileSync(`${homedir()}/.config/omarchy/plugins/rajeevrama.netwatch/Model.js`, "utf8")
  .replace(/^\.pragma library\s*$/m, "")
const M = {}
vm.runInNewContext(source, M)

// Values built inside the VM have its own prototypes; compare their JSON shape.
const eq = (actual, expected) => assert.deepEqual(JSON.parse(JSON.stringify(actual)), expected)

const NET_DEV = `Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:  123456     100    0    0    0     0          0         0   123456     100    0    0    0     0       0          0
wlan0: 5000000    4000    0    0    0     0          0         0   700000     900    0    0    0     0       0          0
tailscale0: 1000 10 0 0 0 0 0 0 2000 20 0 0 0 0 0 0
`

test("parseNetDev reads rx/tx byte columns", () => {
  const d = M.parseNetDev(NET_DEV)
  eq({ ...d.wlan0 }, { rx: 5000000, tx: 700000 })
  eq({ ...d.tailscale0 }, { rx: 1000, tx: 2000 })
  assert.equal(d.lo.rx, 123456)
})

test("ifaceRates divides by elapsed time and treats counter resets as idle", () => {
  const prev = { wlan0: { rx: 1000, tx: 500 }, eth0: { rx: 9000, tx: 9000 } }
  const cur = { wlan0: { rx: 3000, tx: 1500 }, eth0: { rx: 10, tx: 10 }, new0: { rx: 5, tx: 5 } }
  const r = M.ifaceRates(prev, cur, 2)
  eq({ ...r.wlan0 }, { rx: 1000, tx: 500 })
  eq({ ...r.eth0 }, { rx: 0, tx: 0 })
  assert.equal(r.new0, undefined)
  eq({ ...M.ifaceRates(null, cur, 1) }, {})
})

test("interfaces are classified and VPN/virtual ones left out of totals", () => {
  const ifaces = M.parseInterfaces([
    "lo\t0\t0\tunknown",
    "wlan0\t1\t1\tup",
    "enp3s0\t1\t0\tdown",
    "tailscale0\t0\t0\tunknown",
    "docker0\t0\t0\tdown",
    "wwan0\t1\t0\tup"
  ].join("\n"))
  eq(ifaces.map(i => i.name + ":" + i.kind),
    ["wlan0:wifi", "enp3s0:ethernet", "tailscale0:vpn", "docker0:virtual", "wwan0:mobile"])
  assert.equal(ifaces[1].up, false)
  assert.equal(ifaces[2].up, true)  // tun devices report "unknown"
  eq([...M.countedInterfaces(ifaces, "")], ["wlan0", "enp3s0", "wwan0"])
  eq([...M.countedInterfaces(ifaces, "wlan0, tailscale0")], ["wlan0", "tailscale0"])
})

test("sumRates only adds the named interfaces", () => {
  const rates = { wlan0: { rx: 10, tx: 1 }, tailscale0: { rx: 7, tx: 7 } }
  eq({ ...M.sumRates(rates, ["wlan0", "eth0"]) }, { rx: 10, tx: 1 })
})

test("isoWeek matches ISO 8601 at year boundaries", () => {
  eq({ ...M.isoWeek(new Date(2026, 9, 11)) }, { year: 2026, week: 41 })
  eq({ ...M.isoWeek(new Date(2021, 0, 3)) }, { year: 2020, week: 53 })
  eq({ ...M.isoWeek(new Date(2024, 11, 30)) }, { year: 2025, week: 1 })
})

function vnDay(y, m, d, rx, tx) { return { id: 1, date: { year: y, month: m, day: d }, timestamp: 0, rx, tx } }

const DAYS = {
  vnstatversion: "2.13", jsonversion: "2",
  interfaces: [
    { name: "wlan0", traffic: { day: [
      vnDay(2026, 10, 11, 1000, 100), vnDay(2026, 10, 10, 2000, 200), vnDay(2026, 10, 5, 4000, 400),
      vnDay(2026, 10, 4, 8000, 800) ] } },
    { name: "tailscale0", traffic: { day: [vnDay(2026, 10, 11, 50, 50)] } }
  ]
}
const MONTHS = {
  interfaces: [
    { name: "wlan0", traffic: { month: [
      { date: { year: 2026, month: 10 }, rx: 15000, tx: 1500 },
      { date: { year: 2026, month: 9 }, rx: 90000, tx: 9000 } ] } }
  ]
}
const NOW = new Date(2026, 9, 11, 21, 30)  // Sunday, Oct 11 2026

test("day buckets cover the last 14 days, oldest first, counted interfaces only", () => {
  const h = M.parseVnstat(DAYS, MONTHS)
  const b = M.buckets(h, ["wlan0"], "day", NOW)
  assert.equal(b.length, 14)
  assert.equal(b[13].key, "2026-10-11")
  assert.equal(b[13].rx, 1000)
  assert.equal(b[13].tx, 100)
  assert.equal(b[12].rx, 2000)
  assert.equal(b[0].key, "2026-09-28")
  // tailscale0 shows in the breakdown but not in the total
  eq(b[13].interfaces.map(i => i.name + ":" + i.counted), ["wlan0:true", "tailscale0:false"])
  assert.equal(M.bucketTitle(b[13], "day", NOW), "Today")
  assert.equal(M.bucketTitle(b[12], "day", NOW), "Yesterday")
  assert.equal(M.bucketTitle(b[6], "day", NOW), "Sun, Oct 4")
  assert.equal(M.bucketTitle(b[5], "day", NOW), "Sat, Oct 3")
  assert.equal(M.bucketLabel(b[13], "day"), "11")
})

test("week buckets run Monday to Sunday", () => {
  const h = M.parseVnstat(DAYS, MONTHS)
  const b = M.buckets(h, ["wlan0"], "week", NOW)
  assert.equal(b.length, 8)
  // Oct 5 (Mon) .. Oct 11 (Sun) is this week; Oct 4 belongs to the week before.
  assert.equal(b[7].key, "2026-W41")
  assert.equal(b[7].rx, 1000 + 2000 + 4000)
  assert.equal(b[6].rx, 8000)
  assert.equal(M.bucketTitle(b[7], "week", NOW), "This week")
  assert.equal(M.bucketTitle(b[6], "week", NOW), "Last week")
  assert.equal(M.bucketTitle(b[5], "week", NOW), "Sep 21 – 27")
  assert.equal(M.bucketTitle(b[4], "week", NOW), "Sep 14 – 20")
  assert.equal(M.bucketLabel(b[7], "week"), "W41")
})

test("week titles spanning two months name both", () => {
  const b = M.buckets({}, [], "week", new Date(2026, 10, 3))  // Tue, Nov 3
  assert.equal(M.bucketTitle(b[6], "week", new Date(2026, 10, 3)), "Last week")
  assert.equal(M.bucketTitle(b[7], "week", new Date(2026, 10, 3)), "This week")
  assert.equal(M.bucketTitle(b[5], "week", new Date(2026, 10, 3)), "Oct 19 – 25")
  assert.equal(M.bucketTitle(M.buckets({}, [], "week", new Date(2026, 10, 10))[6], "week", new Date(2026, 10, 10)), "Last week")
  assert.equal(M.bucketTitle(M.buckets({}, [], "week", new Date(2026, 10, 10))[5], "week", new Date(2026, 10, 10)), "Oct 26 – Nov 1")
})

test("month buckets use the month table", () => {
  const h = M.parseVnstat(DAYS, MONTHS)
  const b = M.buckets(h, ["wlan0"], "month", NOW)
  assert.equal(b.length, 12)
  assert.equal(b[11].key, "2026-10")
  assert.equal(b[11].rx + b[11].tx, 16500)
  assert.equal(b[10].rx + b[10].tx, 99000)
  assert.equal(b[0].key, "2025-11")
  assert.equal(M.bucketTitle(b[11], "month", NOW), "This month")
  assert.equal(M.bucketTitle(b[10], "month", NOW), "September 2026")
  assert.equal(M.bucketLabel(b[10], "month"), "Sep")
})

test("changeText compares finished periods with the one before", () => {
  const b = [{ rx: 100, tx: 0 }, { rx: 150, tx: 0 }, { rx: 75, tx: 0 }, { rx: 1, tx: 0 }]
  eq(M.changeText(b, 2, "day"), "−50% vs the day before")
  eq(M.changeText(b, 1, "week"), "+50% vs the week before")
  eq(M.changeText(b, 0, "day"), "")
  eq(M.changeText([{ rx: 0, tx: 0 }, { rx: 5, tx: 0 }, { rx: 1, tx: 0 }], 1, "week"), "")
  eq(M.changeText([{ rx: 5, tx: 0 }, { rx: 5, tx: 0 }, { rx: 1, tx: 0 }], 1, "month"), "Same as the month before")
})

test("changeText compares the period in progress with the same stretch before it", () => {
  const h = M.parseVnstat(DAYS, MONTHS)
  // Today is a whole day still running: show yesterday's total instead of a percentage.
  const days = M.buckets(h, ["wlan0"], "day", NOW)
  eq(M.changeText(days, 13, "day", h, ["wlan0"], NOW), "Yesterday: 2.2 kB")
  // Mon Oct 5 .. Sun Oct 11 vs Mon Sep 28 .. Sun Oct 4: 7700 vs 8800 (−12.5%).
  const weeks = M.buckets(h, ["wlan0"], "week", NOW)
  eq(M.changeText(weeks, 7, "week", h, ["wlan0"], NOW), "−12% vs this point last week")
  // Oct 1..11 vs Sep 1..11: September has no daily data here, so no claim.
  const months = M.buckets(h, ["wlan0"], "month", NOW)
  eq(M.changeText(months, 11, "month", h, ["wlan0"], NOW), "")
  const withSep = M.parseVnstat({ interfaces: [{ name: "wlan0", traffic: { day: [
    vnDay(2026, 9, 3, 1000, 0), vnDay(2026, 9, 20, 99999, 0), vnDay(2026, 10, 2, 1500, 0) ] } }] }, MONTHS)
  eq(M.changeText(months, 11, "month", withSep, ["wlan0"], NOW), "+50% vs this point last month")
})

test("parseStatus and firewallState", () => {
  const missing = M.parseStatus("")
  assert.equal(missing.vnstat, "missing")
  assert.equal(missing.opensnitch, "missing")
  assert.equal(M.firewallState(missing).level, "missing")

  const s = M.parseStatus([
    "vnstat_bin=1", "opensnitch_bin=1", "nethogs_bin=1",
    "vnstat=active", "opensnitchd=active", "rules=6",
    "helper=1"
  ].join("\n"))
  assert.equal(s.vnstat, "active")
  assert.equal(s.nethogs, true)
  assert.equal(s.ui, false)
  assert.equal(s.helper, true)
  assert.equal(missing.helper, false)
  assert.equal(M.firewallState(s).level, "paused")
  s.ui = true
  assert.equal(M.firewallState(s).level, "ok")
  assert.equal(M.firewallState(s).detail, "6 rules saved from your answers")
  s.rules = 1
  assert.equal(M.firewallState(s).detail, "1 rule saved from your answers")
  s.opensnitch = "failed"
  assert.equal(M.firewallState(s).level, "off")
})

test("bar label and compact rates", () => {
  assert.equal(M.formatRateShort(0), "0K")
  assert.equal(M.formatRateShort(1234567), "1.2M")
  assert.equal(M.formatRateShort(640000), "640K")
  const rate = { rx: 1234567, tx: 40000 }
  assert.equal(M.barLabel(rate, "none", true), "")
  assert.equal(M.barLabel(rate, "active", false), "")
  assert.equal(M.barLabel(rate, "active", true), M.GLYPH_DOWN + "1.2M " + M.GLYPH_UP + "40K")
  assert.equal(M.barLabel(rate, "always", false), M.GLYPH_DOWN + "1.2M " + M.GLYPH_UP + "40K")
  assert.equal(M.nextLabelMode("none"), "active")
})

// What netwatch-rules export writes (see bin/netwatch-rules).
const EXPORT = JSON.stringify({
  generated: "2026-10-12T02:00:00Z",
  rules: [
    { file: "000-netwatch-block-domains.json", name: "000-netwatch-block-domains", action: "reject",
      operator: { type: "lists", operand: "lists.domains", data: "/etc/opensnitchd/netwatch/block-domains" } },
    { file: "002-netwatch-allow-pacman.json", name: "002-netwatch-allow-pacman", action: "allow", enabled: true,
      operator: { type: "simple", operand: "process.path", data: "/usr/bin/pacman" } },
    { file: "allow-always-simple-usr-bin-telegram.json", name: "allow-always-simple-usr-bin-telegram",
      action: "allow", enabled: true, operator: { type: "simple", operand: "process.path", data: "/usr/bin/telegram" } },
    { file: "deny-always-simple-usr-bin-cliamp.json", name: "deny-always-simple-usr-bin-cliamp",
      action: "deny", enabled: false, operator: { type: "simple", operand: "process.path", data: "/usr/bin/cliamp" } },
    { file: "allow-always-list-curl-example.json", name: "allow-always-list-curl-example", action: "allow", enabled: true,
      operator: { type: "list", operand: "list", list: [
        { type: "simple", operand: "process.path", data: "/usr/bin/curl" },
        { type: "simple", operand: "dest.host", data: "example.com" },
        { type: "simple", operand: "dest.port", data: "443" } ] } },
    { file: "deny-always-simple-1-2-3-4.json", name: "deny-always-simple-1-2-3-4", action: "reject", enabled: true,
      operator: { type: "simple", operand: "dest.ip", data: "1.2.3.4" } },
    { file: "broken.json", error: "Expecting value" }
  ],
  lists: { "block-domains": ["ads.example.com"], "allow-domains": [], "block-nets": ["203.0.113.0/24"], "allow-nets": null }
})

test("parseRules turns rules and list entries into rows", () => {
  eq(M.parseRules(""), { ok: false, items: [] })
  eq(M.parseRules("NETWATCH_NO_EXPORT"), { ok: false, items: [] })
  eq(M.parseRules("{"), { ok: false, items: [] })

  const r = M.parseRules(EXPORT)
  assert.equal(r.ok, true)
  const byId = Object.fromEntries(r.items.map(i => [i.id, i]))
  // list-reading rules and unreadable files are left out
  assert.equal(byId["rule:000-netwatch-block-domains.json"], undefined)
  assert.equal(byId["rule:broken.json"], undefined)
  eq(byId["rule:002-netwatch-allow-pacman.json"].kind, "system")
  const telegram = byId["rule:allow-always-simple-usr-bin-telegram.json"]
  eq([telegram.kind, telegram.action, telegram.title, telegram.detail], ["app", "allow", "telegram", "/usr/bin/telegram"])
  const cliamp = byId["rule:deny-always-simple-usr-bin-cliamp.json"]
  eq([cliamp.action, cliamp.enabled, cliamp.detail], ["block", false, "off · /usr/bin/cliamp"])
  const curl = byId["rule:allow-always-list-curl-example.json"]
  eq([curl.title, curl.detail], ["curl", "to example.com · port 443 · /usr/bin/curl"])
  const ip = byId["rule:deny-always-simple-1-2-3-4.json"]
  eq([ip.kind, ip.action, ip.title], ["address", "block", "1.2.3.4"])
  const ads = byId["list:block-domains:ads.example.com"]
  eq([ads.kind, ads.action, ads.detail], ["site", "block", "Blocked for every app"])
  eq(byId["list:block-nets:203.0.113.0/24"].kind, "address")
})

test("counting, filtering and grouping rows", () => {
  const items = M.parseRules(EXPORT).items
  eq(M.countItems(items), { all: 7, allow: 3, block: 4 })
  eq(M.filterItems(items, "allow", "").map(i => i.title).sort(), ["curl", "pacman", "telegram"])
  eq(M.filterItems(items, "all", "EXAMPLE").map(i => i.title).sort(), ["ads.example.com", "curl"])
  eq(M.filterItems(items, "block", "usr/bin").map(i => i.title), ["cliamp"])

  const sections = M.sectionItems(items)
  eq(sections.map(s => s.kind), ["app", "site", "address", "system"])
  // blocked first, then alphabetical
  eq(sections[0].items.map(i => i.title), ["cliamp", "curl", "telegram"])
  eq(sections[2].items.map(i => i.title), ["1.2.3.4", "203.0.113.0/24"])
  eq(M.flattenSections(sections).length, 7)
})

test("helper arguments for flipping, deleting and adding", () => {
  const byId = Object.fromEntries(M.parseRules(EXPORT).items.map(i => [i.id, i]))
  eq(M.flipArgs(byId["rule:allow-always-simple-usr-bin-telegram.json"]),
    ["set-action", "allow-always-simple-usr-bin-telegram.json", "deny"])
  eq(M.flipArgs(byId["rule:deny-always-simple-1-2-3-4.json"]), ["set-action", "deny-always-simple-1-2-3-4.json", "allow"])
  eq(M.flipArgs(byId["list:block-domains:ads.example.com"]), ["list-add", "allow-domains", "ads.example.com"])
  eq(M.flipArgs(byId["list:block-nets:203.0.113.0/24"]), ["list-add", "allow-nets", "203.0.113.0/24"])
  eq(M.deleteArgs(byId["rule:deny-always-simple-usr-bin-cliamp.json"]), ["delete", "deny-always-simple-usr-bin-cliamp.json"])
  eq(M.deleteArgs(byId["list:block-domains:ads.example.com"]), ["list-remove", "block-domains", "ads.example.com"])
  eq(M.addArgs(M.classifyEntry("Tracker.Example.com"), "block"), ["list-add", "block-domains", "tracker.example.com"])
  eq(M.addArgs(M.classifyEntry("10.0.0.0/8"), "allow"), ["list-add", "allow-nets", "10.0.0.0/8"])
})

test("classifyEntry gives an immediate hint", () => {
  eq(M.classifyEntry(""), { ok: false, error: "" })
  eq(M.classifyEntry(" example.com. "), { ok: true, kind: "site", value: "example.com" })
  eq(M.classifyEntry("203.0.113.7").kind, "address")
  eq(M.classifyEntry("2001:db8::/32").kind, "address")
  assert.equal(M.classifyEntry("*.example.com").ok, false)
  assert.match(M.classifyEntry("*.example.com").error, /Wildcards/)
  assert.equal(M.classifyEntry("300.1.1.1").ok, false)
  assert.equal(M.classifyEntry("10.0.0.0/0").ok, false)
  assert.equal(M.classifyEntry("not a domain").ok, false)
  assert.equal(M.classifyEntry("localhost").ok, false)
})

test("helper run results", () => {
  eq(M.parseHelperRun("NETWATCH_EXIT=0\n"), { exitCode: 0, output: "" })
  eq(M.parseHelperRun("a rule named x already exists\nNETWATCH_EXIT=3\n"),
    { exitCode: 3, output: "a rule named x already exists\n" })
  eq(M.parseHelperRun("garbage"), { exitCode: 1, output: "garbage" })
  eq(M.helperOutcome(0, ""), { ok: true, text: "" })
  eq(M.helperOutcome(126, "Error executing command as another user: Request dismissed"),
    { ok: false, text: "Cancelled — nothing was changed" })
  eq(M.helperOutcome(3, "not a domain name: 'x'\n"), { ok: false, text: "not a domain name: 'x'" })
  eq(M.helperOutcome(1, ""), { ok: false, text: "Couldn't save the change (exit 1)" })
})
