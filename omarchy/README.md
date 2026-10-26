# Bahya Nireekshana for Omarchy

Network monitoring for an Omarchy machine, built from packaged tools plus a
bar widget. (This part was called *netwatch* before; `install.sh` moves an
older netwatch setup over to the new names and keeps your lists.)

| Need | Provided by |
|------|-------------|
| Live upload/download speed in the bar | `rajeevrama.nireekshana` widget (reads `/proc/net/dev`, no privileges) |
| Daily / weekly / monthly usage per connection | vnstat (`vnstat.service`), shown in the widget panel |
| Live usage per app (GUI apps, scripts, CLI tools, system services) | nethogs, opened from the widget in a terminal (`sudo nethogs -C`) |
| Approval prompts for apps that haven't connected before | OpenSnitch (`opensnitchd.service` + `opensnitch-ui` at login) |
| Blocklist / allowlist | OpenSnitch rules using the list files in `/etc/opensnitchd/nireekshana/` |
| Reviewing and changing what's allowed or blocked | The widget's **Allowed & blocked** page, via `nireekshana-rules` |

Not covered: per-app usage *history* (bytes per app per day/week/month).
nethogs only shows the live picture; OpenSnitch's statistics window keeps
per-app connection counts, not data volume.

## Setup

```bash
omarchy/install-plugin.sh        # the bar widget, for your user (no sudo)
sudo omarchy/install.sh          # the system side; safe to re-run, never overwrites edited lists/rules
omarchy/install.sh --check       # status only
```

`install-plugin.sh` copies `plugin/` to
`~/.config/omarchy/plugins/rajeevrama.nireekshana` and puts the widget in the
bar after the network icon (an old netwatch widget is replaced in place). Until the setup script has
run, its panel offers a **Set up** button that opens this script in a terminal.

## Using the widget

- **Bar:** shows `↓1.2M ↑40K` while something is transferring.
  - The icon turns the accent colour during a transfer.
  - A red dot means OpenSnitch is stopped, or its prompt window isn't running.
- **Clicks:** left-click opens the panel, right-click cycles the label (only while transferring / always / never), middle-click opens live per-app usage.
- **Panel:**
  - live speed graphs
  - usage history with Day / Week / Month views (`d` / `w` / `m`): hover a bar or press `h` / `l` to pick a period
  - a per-interface breakdown
  - firewall status
  - **Allowed & blocked**: every saved OpenSnitch answer and list entry (see below)
  - shortcuts to live per-app usage and the OpenSnitch window
- **Settings** (`~/.config/omarchy/shell.json`, `rajeevrama.nireekshana` entry):
  - `label`: `active`, `always` or `none`
  - `interfaces`: e.g. `"wlan0,enp3s0"`; empty means Wi‑Fi, Ethernet and mobile links. VPN tunnels are left out so traffic isn't counted twice.
  - `firewallBadge`

## Allowed & blocked

Open it from the widget panel (the row with the arrow). It lists:
- apps you've answered OpenSnitch prompts for with "always"
- sites and IP addresses/networks on the Bahya Nireekshana blocklists and allowlists
- the system services `install.sh` pre-allowed

Each row shows whether it's allowed or blocked. Filter with All / Allowed /
Blocked (`1` `2` `3`) or search (`/`).

What you can do there:
- **Block / Allow** a row (Enter): an app rule switches between allow and deny; a list entry moves to the other list.
- **Remove** a row (`x`): a removed app answer means OpenSnitch asks about that app again next time.
- **Add** a domain, IP address or network to block or allow for every app (`a` to jump to the field).

Changes run `/usr/local/bin/nireekshana-rules` through `pkexec`. Omarchy's
password prompt asks once, then remembers for a few minutes. OpenSnitch saves
its rules readable by root only, so the same helper exports a summary to
`/run/nireekshana/rules.json` (readable by the `wheel` group). A systemd path unit
refreshes it whenever rules or lists change.

Answers given for a limited time (e.g. "until restart") live only inside
OpenSnitch; see them in the OpenSnitch window.

## Blocklists and allowlist files

The page edits these for you. You can also use `sudoedit`; OpenSnitch reloads
them on save:

- `/etc/opensnitchd/nireekshana/block-domains/list.txt`: `0.0.0.0 example.com` per line
- `/etc/opensnitchd/nireekshana/block-nets/list.txt`: CIDR per line (`203.0.113.7/32`)
- `/etc/opensnitchd/nireekshana/allow-domains/list.txt`: `0.0.0.0 example.com` per line
- `/etc/opensnitchd/nireekshana/allow-nets/list.txt`: CIDR per line

Rule order:
- Blocklists (`000-nireekshana-*` rules) win over everything.
- The allowlist (`001-…`) comes next.
- Then the answers you give in OpenSnitch prompts.

`install.sh` also pre-allows systemd-resolved, systemd-timesyncd,
NetworkManager and pacman, so DNS, time sync and updates work before you've
answered any prompts.

## Files

- `install-plugin.sh`: the bar widget (`plugin/`) for your user
- `install.sh` / `uninstall.sh` (`--purge` also removes the packages and vnstat history)
- `bin/nireekshana-rules`: the root helper behind the Allowed & blocked page (installed to `/usr/local/bin`)
- `systemd/nireekshana-rules-export.{service,path}`, `polkit/local.rajeevrama.nireekshana.rules.policy`
- Tests:
  - `node --test tests/model.test.mjs`: the widget's data logic
  - `python3 -I -m unittest discover -s tests`: the helper, run unprivileged against temp dirs
