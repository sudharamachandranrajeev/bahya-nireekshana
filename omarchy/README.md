# Bahya Nireekshana for Omarchy

Network monitoring for an Omarchy machine, built from packaged tools plus a
bar widget. (This part was called *netwatch* before; `install.sh` moves an
older netwatch setup over to the new names and keeps your lists.)

| Need | Provided by |
|------|-------------|
| Live upload/download speed in the bar | `rajeevrama.nireekshana` widget (reads `/proc/net/dev`, no privileges) |
| Daily / weekly / monthly usage per connection | vnstat (`vnstat.service`), shown in the widget panel |
| Live usage per app (GUI apps, scripts, CLI tools, system services) | nethogs, opened from the widget in a terminal (`sudo nethogs -C`) |
| Daily usage per app, for the app's Apps page | `nireekshana-apps.service`: reads nethogs in trace mode and writes `/var/lib/nireekshana/apps.json` |
| Approval prompts for apps that haven't connected before | OpenSnitch (`opensnitchd.service` + `opensnitch-ui` at login) |
| Each prompt explained in plain words | The `nireekshana` OpenSnitch plugin (`opensnitch/nireekshana/`) |
| Blocklist / allowlist | OpenSnitch rules using the list files in `/etc/opensnitchd/nireekshana/` |
| Reviewing and changing what's allowed or blocked | The widget's **Allowed & blocked** page, via `nireekshana-rules` |

The per-app counter only counts while it runs (from when `install.sh` set it
up), and assigns traffic to the kind of network the default route used at
the time.

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

## Prompts in plain words

`install.sh` adds a plugin to OpenSnitch's prompt window. Under the prompt's own question you get
a coloured line:

- 🟢 **Looks routine**: a known program, installed by the package manager, doing its usual job.
- 🟠 **Worth a look**: something is unknown or unusual. For example, no package installed the
  program, or it runs as root without being a system service.
- 🔴 **Be careful**: a red flag. For example, the program runs from a temporary folder, its file
  was deleted after it started, a script runs from a temporary folder, or the port is one that
  remote-control tools use by default.

**Explain…** opens the whole story. Opening it also stops the countdown. It has two tabs:

- **In plain words**:
  - **What is it**: a description from Bahya Nireekshana's list, the app's menu entry and the
    package database.
  - **What it's for**.
  - **Who it's talking to**: the site's owner, whether the address is this computer, your own
    network or the internet, and what the port means.
  - **Why now**:
    - a scheduled job (systemd timer)
    - a background service
    - started from a terminal or by another app
    - how long it has been running
  - **If you allow** and **If you deny**: what happens either way.
  - **If you don't answer**: what OpenSnitch saves when the countdown runs out.
  - **Things to notice**: any red flags.
- **Advanced**:
  - the program, its command line and the script it runs
  - process ID and user
  - how long it has been running
  - package and version
  - the systemd unit and what triggered it
  - the chain of programs that started it
  - the destination address, its type and the site's owner
  - protocol, port and checksum

Everything comes from this computer: `/proc`, pacman's database, `systemctl` and
`opensnitch/nireekshana/known.json`, a list of programs, sites and ports. It makes no network
requests. Program names, arguments and host names come from the connection and are shown
escaped, never as live markup.

How it is wired up:
- OpenSnitch loads plugins only from its own package folder. `install.sh` copies the plugin to
  `/usr/local/lib/nireekshana/opensnitch/nireekshana/`, and `nireekshana-link-plugin` links it
  into `…/site-packages/opensnitch/plugins/`.
- A pacman hook runs the link again after OpenSnitch or Python updates. A new Python version
  moves the folder.
- `~/.config/opensnitch/actions/nireekshana.json` switches it on. Set `"enabled": false` there
  to switch it off.

Try the explanation for a running process from a terminal:

```bash
python3 omarchy/opensnitch/nireekshana/explain.py <pid> <host-or-ip> <port>
```

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
- `opensnitch/nireekshana/`: the prompt explainer (`nireekshana.py` is the plugin, `explain.py`
  the logic, `known.json` the list of programs, sites and ports), with `bin/nireekshana-link-plugin`
  and `pacman/nireekshana-opensnitch-plugin.hook`
- Tests:
  - `node --test tests/model.test.mjs`: the widget's data logic
  - `python3 -I -m unittest discover -s tests`: the helpers and the prompt explainer, run
    unprivileged against temp dirs and fake look-ups
