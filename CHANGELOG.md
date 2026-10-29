# Changelog

## 0.3.0 (2026-10-29)

- Firewall prompts in plain words (Linux). When OpenSnitch asks about a connection, a coloured
  line now says whether it looks routine, is worth a look, or needs care.
- **Explain…** in the prompt opens the whole story:
  - what the program is and what it's for
  - who it's talking to
  - why it's asking now: a scheduled job, a background service, something started from a terminal
    or by another app
  - what allowing or denying will do, and what happens if you don't answer
  - any red flags
- An **Advanced** tab shows the details behind the explanation: process tree, package, systemd
  unit and timer, the script an interpreter runs, address type, port and checksum.
- Opening the explanation stops the prompt's countdown.
- The explanation is built only from what is on the computer. It makes no network requests. Run
  `sudo omarchy/install.sh` again to add it.
- The release pipeline uses the current GitHub Actions (checkout 7, setup-node 7, setup-java 6,
  upload-artifact 7, download-artifact 8). Downloaded build artifacts are now checked against
  their digest, and a mismatch fails the release.
- Security problems can be reported privately from the repository's Security tab; see
  SECURITY.md.

## 0.2.1 (2026-10-26)

- The Windows app builds again with Visual Studio 2026. 0.2.0 was never published because of
  this; 0.2.1 carries everything listed under it.

## 0.2.0 (2026-10-26)

- Apps: each app's data use today, over 7 or 30 days or this month, against the period before.
  Every app ranked with its share, download and upload, new apps, the top three's share and the
  share moved in the background (Android). Tap an app for its last 30 days, busiest day, daily
  average, and the networks and devices it used. Filter by device or kind of network.
- Android reads each app's usage from the system's network statistics (usage access, which the
  device history already asks for). Windows reads its own data usage per app. On Linux, the new
  `nireekshana-apps` service counts each program with nethogs; run `sudo omarchy/install.sh` once
  to set it up.
- Usage per app syncs with your other devices; forgetting a device forgets its apps too.
- The database moves to version 2; existing data is kept.
- Usage chart labels no longer run into each other or off the edge, and a plan's period marker is
  a tick again.

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
