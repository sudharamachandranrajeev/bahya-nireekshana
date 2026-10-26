# netwatch

Network monitoring for this Omarchy machine, built from packaged tools plus a
bar widget.

| Need | Provided by |
|------|-------------|
| Live upload/download speed in the bar | `rajeevrama.netwatch` widget (reads `/proc/net/dev`, no privileges) |
| Daily / weekly / monthly usage per connection | vnstat (`vnstat.service`), shown in the widget panel |
| Live usage per app (GUI apps, scripts, CLI tools, system services) | nethogs, opened from the widget in a terminal (`sudo nethogs -C`) |
| Approval prompts for apps that haven't connected before | OpenSnitch (`opensnitchd.service` + `opensnitch-ui` at login) |
| Blocklist / allowlist | OpenSnitch rules using the list files in `/etc/opensnitchd/netwatch/` |
| Reviewing and changing what's allowed or blocked | The widget's **Allowed & blocked** page, via `netwatch-rules` |

Not covered: per-app usage *history* (bytes per app per day/week/month).
nethogs only shows the live picture; OpenSnitch's statistics window keeps
per-app connection counts, not data volume.

## Setup

```bash
sudo ~/Work/netwatch/install.sh      # safe to re-run; never overwrites edited lists/rules
~/Work/netwatch/install.sh --check   # status only
```

The widget is already in the bar, right after the network icon (it lives in
`~/.config/omarchy/plugins/rajeevrama.netwatch`). Until the setup script has
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
- **Settings** (`~/.config/omarchy/shell.json`, `rajeevrama.netwatch` entry):
  - `label`: `active`, `always` or `none`
  - `interfaces`: e.g. `"wlan0,enp3s0"`; empty means Wi‑Fi, Ethernet and mobile links. VPN tunnels are left out so traffic isn't counted twice.
  - `firewallBadge`

## Allowed & blocked

Open it from the widget panel (the row with the arrow). It lists:
- apps you've answered OpenSnitch prompts for with "always"
- sites and IP addresses/networks on the netwatch blocklists and allowlists
- the system services `install.sh` pre-allowed

Each row shows whether it's allowed or blocked. Filter with All / Allowed /
Blocked (`1` `2` `3`) or search (`/`).

What you can do there:
- **Block / Allow** a row (Enter): an app rule switches between allow and deny; a list entry moves to the other list.
- **Remove** a row (`x`): a removed app answer means OpenSnitch asks about that app again next time.
- **Add** a domain, IP address or network to block or allow for every app (`a` to jump to the field).

Changes run `/usr/local/bin/netwatch-rules` through `pkexec`. Omarchy's
password prompt asks once, then remembers for a few minutes. OpenSnitch saves
its rules readable by root only, so the same helper exports a summary to
`/run/netwatch/rules.json` (readable by the `wheel` group). A systemd path unit
refreshes it whenever rules or lists change.

Answers given for a limited time (e.g. "until restart") live only inside
OpenSnitch; see them in the OpenSnitch window.

## Blocklists and allowlist files

The page edits these for you. You can also use `sudoedit`; OpenSnitch reloads
them on save:

- `/etc/opensnitchd/netwatch/block-domains/list.txt`: `0.0.0.0 example.com` per line
- `/etc/opensnitchd/netwatch/block-nets/list.txt`: CIDR per line (`203.0.113.7/32`)
- `/etc/opensnitchd/netwatch/allow-domains/list.txt`: `0.0.0.0 example.com` per line
- `/etc/opensnitchd/netwatch/allow-nets/list.txt`: CIDR per line

Rule order:
- Blocklists (`000-netwatch-*` rules) win over everything.
- The allowlist (`001-…`) comes next.
- Then the answers you give in OpenSnitch prompts.

`install.sh` also pre-allows systemd-resolved, systemd-timesyncd,
NetworkManager and pacman, so DNS, time sync and updates work before you've
answered any prompts.

## Files

- `install.sh` / `uninstall.sh` (`--purge` also removes the packages and vnstat history)
- `bin/netwatch-rules`: the root helper behind the Allowed & blocked page (installed to `/usr/local/bin`)
- `systemd/netwatch-rules-export.{service,path}`, `polkit/local.rajeevrama.netwatch.rules.policy`
- Tests:
  - `node --test tests/model.test.mjs`: the widget's data logic
  - `python3 -I -m unittest discover -s tests`: the helper, run unprivileged against temp dirs
