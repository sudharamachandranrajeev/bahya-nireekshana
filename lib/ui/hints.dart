/// Bahya Nireekshana's hints, by id, on top of the shared ones (coreHints).
/// Page banners (ids starting `page.`) explain a whole screen once.
const nireekshanaHints = <String, String>{
  'nav.now': 'Live speed, today’s usage and anything that needs a look.',
  'nav.usage': 'Usage by day, week and month, on every synced device.',
  'nav.apps': 'Which apps use the most data, and when.',
  'nav.plans': 'Data allowances and how far through them you are.',
  'nav.speed': 'Measure the connection’s speed and keep the results.',
  'nav.connections': 'Which programs are talking to the network right now.',
  'nav.firewall': 'OpenSnitch rules and the block and allow lists.',
  'nav.themes': 'Pick, make and share themes.',
  'nav.settings': 'Updates, alerts, sync, hints and security.',
  'action.export': 'Save every device’s daily usage as a CSV file for a spreadsheet.',
  'usage.source':
      'Where this device’s history comes from. A system record (vnstat on Linux, Android’s network '
      'statistics) counts even while the app is closed; otherwise the app counts while it runs.',
  'usage.projection': 'A whole month at this month’s pace so far.',
  'usage.change': 'This month against the same days of last month.',
  'apps.list': 'Tap an app for its daily chart, its busiest day and where it was used.',
  'apps.top':
      'How much of the traffic the three busiest apps moved. High means a few apps use most of your data.',
  'apps.background':
      'Data moved while the app was not on screen: syncing, updates, backups. Android reports this; other '
      'systems do not.',
  'plan.budget': 'What you can use each remaining day, today included, and stay inside the allowance.',
  'speed.how':
      'Downloads and uploads test data from Cloudflare’s public speed test for about ten seconds each. '
      'The speed shown is the 90th percentile of the transfers, so one slow start does not drag it down.',
  'page.now':
      'Download is drawn above the line and upload below it. Today counts every device that syncs with '
      'this one.',
  'page.usage':
      'Tap a bar to see that day, week or month. Filter by device or kind of network; the figures and '
      'breakdowns follow the filter.',
  'page.apps':
      'Each app’s data use from the system’s own record: Android’s network statistics, Windows’ data usage, '
      'or the nireekshana-apps service on Linux. Compare a period with the one before; filter by device or '
      'network.',
  'page.plans':
      'Add your mobile or broadband allowance and the day it renews. Bahya Nireekshana warns as you near '
      'it and says what you can use each day to stay inside.',
  'page.connections':
      'Each program’s open connections, read from the system a moment ago. Only your own programs show '
      'their names unless the app runs with more rights.',
  'page.firewall':
      'Rules OpenSnitch saved from your answers, and the block and allow lists. Changes ask for your '
      'password through the system.',
  'page.themes':
      'Themes set the colours, the corner roundness and the font. Make your own from scratch or from a '
      'copy, and share them as a small JSON file. The browser extension reads the same files.',
};
