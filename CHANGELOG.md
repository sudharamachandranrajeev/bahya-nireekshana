# Changelog

## 0.1.0 (2026-10-26)

The first release of the app, after the Omarchy widget (formerly *netwatch*).

- Now: live download and upload gauges, a two-minute chart, today, yesterday, this month, the
  nearest data plan, every interface, and a note when today runs well above your usual day.
- Usage: days, weeks or months, filtered by kind of network or device, with figures, the month's
  projection, breakdowns and CSV export. History comes from vnstat on Linux and the system's
  network statistics on Android when they are there, else from the app's own counters.
- Data plans with renewal day, pace, a daily allowance to stay inside and a warning level.
- Speed test against Cloudflare: download, upload, latency and jitter, with history.
- Connections by program on Linux and Windows; firewall lists and OpenSnitch rules on Linux.
- Themes: eight built in, light, dark or system, and a theme manager to make, edit, import and
  export your own.
- In-app updater on Linux, Windows and Android, checked against the release's SHA256SUMS.txt.
- Encrypted database and optional end-to-end encrypted sync across your devices.
- Browser extension for Chrome, Edge and Firefox: data used by each website, a dashboard, a
  blocklist, daily budgets and the app's themes.
