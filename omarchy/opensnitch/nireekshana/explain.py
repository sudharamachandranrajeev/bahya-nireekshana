"""Explains an OpenSnitch connection prompt in plain words.

Pure logic plus a few local look-ups (/proc, the pacman database, systemd).
Nothing here touches the network: the explanation is built from what is on
this computer and from known.json. Everything that comes from the connection
(program names, arguments, host names) is untrusted text; callers must escape
it before showing it as rich text.

explain(conn, known, system) returns:
  headline   one sentence: who wants to reach what
  verdict    {"level": "routine" | "check" | "caution", "label", "advice"}
  plain      [(title, text)]: what it is, what it's for, who it's talking to,
             why now, if you allow, if you deny, things to notice
  advanced   [(label, value)]: the technical details behind the plain text
"""

import html
import ipaddress
import json
import os
import re
import subprocess
import time

HERE = os.path.dirname(os.path.realpath(__file__))
KNOWN = os.path.join(HERE, "known.json")

TERMINALS = {
    "alacritty", "kitty", "ghostty", "foot", "wezterm-gui", "konsole", "gnome-terminal-server",
    "xterm", "urxvt", "st", "terminator", "tilix", "xfce4-terminal", "ptyxis", "rio",
}
SHELLS = {"bash", "sh", "zsh", "fish", "dash", "nu"}
INTERPRETERS = {"python", "python3", "node", "perl", "ruby", "java", "bun", "deno", "dart"} | SHELLS
# Folders anyone (or any program) can write to, where installed software doesn't live.
SCRATCH_DIRS = ("/tmp/", "/var/tmp/", "/dev/shm/", "/run/user/")
LAN_NETS = [ipaddress.ip_network(n) for n in ("10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "fc00::/7")]
VERSIONED = re.compile(r"^(python|perl|ruby|node|java)[0-9.]*$")


def load_known(path=KNOWN):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


class System:
    """Local look-ups. Each returns None when it can't tell; none raise."""

    def __init__(self, proc="/proc", pacman_db="/var/lib/pacman/local", timeout=2.0):
        self.proc = proc
        self.pacman_db = pacman_db
        self.timeout = timeout

    def _run(self, *args):
        try:
            out = subprocess.run(
                args, capture_output=True, text=True, timeout=self.timeout, env={"LC_ALL": "C", "PATH": "/usr/bin:/bin"}
            )
        except (OSError, subprocess.SubprocessError):
            return None
        return out.stdout.strip() if out.returncode == 0 else None

    def owner(self, path):
        """The pacman package that installed path."""
        if not path.startswith("/") or not os.path.isfile(path):
            return None
        return self._run("pacman", "-Qqo", "--", path) or None

    def package(self, name):
        """{name, version, description, url} from pacman's local database."""
        try:
            entries = os.listdir(self.pacman_db)
        except OSError:
            return None
        for entry in entries:
            if not entry.startswith(name + "-"):
                continue
            try:
                with open(os.path.join(self.pacman_db, entry, "desc"), encoding="utf-8") as f:
                    fields = parse_desc(f.read())
            except OSError:
                continue
            if fields.get("NAME") == name:
                return {
                    "name": name,
                    "version": fields.get("VERSION", ""),
                    "description": fields.get("DESC", ""),
                    "url": fields.get("URL", ""),
                }
        return None

    def unit(self, pid):
        """("system" | "user", unit name) the process runs in, from its cgroup."""
        try:
            with open(os.path.join(self.proc, str(pid), "cgroup"), encoding="utf-8") as f:
                text = f.read()
        except (OSError, ValueError):
            return None
        return unit_from_cgroup(text)

    def unit_info(self, scope, unit):
        """{description, triggered_by} for a systemd unit."""
        args = ["systemctl"] + (["--user"] if scope == "user" else []) + [
            "show", "--property=Description,TriggeredBy", "--", unit
        ]
        out = self._run(*args)
        if out is None:
            return None
        info = dict(line.split("=", 1) for line in out.splitlines() if "=" in line)
        return {"description": info.get("Description", ""), "triggered_by": info.get("TriggeredBy", "")}

    def age(self, pid):
        """Seconds since the process started."""
        try:
            with open(os.path.join(self.proc, str(pid), "stat"), encoding="utf-8") as f:
                stat = f.read()
            with open(os.path.join(self.proc, "uptime"), encoding="utf-8") as f:
                uptime = float(f.read().split()[0])
        except (OSError, ValueError, IndexError):
            return None
        # The command name (field 2) can hold spaces and brackets: count from the last ')'.
        fields = stat[stat.rfind(")") + 2:].split()
        try:
            start = int(fields[19]) / os.sysconf("SC_CLK_TCK")
        except (IndexError, ValueError):
            return None
        return max(0.0, uptime - start)

    def exe(self, pid):
        """Where /proc says the running program is; ends in ' (deleted)' if the file is gone."""
        try:
            return os.readlink(os.path.join(self.proc, str(pid), "exe"))
        except OSError:
            return None


def parse_desc(text):
    fields, key = {}, None
    for line in text.splitlines():
        if line.startswith("%") and line.endswith("%"):
            key = line[1:-1]
        elif key and line and key not in fields:
            fields[key] = line
    return fields


def unit_from_cgroup(text):
    for line in text.splitlines():
        path = line.split(":", 2)[-1]
        parts = [p for p in path.split("/") if p]
        for part in reversed(parts):
            if part.endswith((".service", ".scope")):
                scope = "user" if "user@" in path else "system"
                return scope, part
    return None


# ---------- small helpers ----------


def base(path):
    return os.path.basename(path or "")


def program_key(name, known):
    if name in known["programs"]:
        return name
    plain = VERSIONED.sub(r"\1", name)
    return plain if plain in known["programs"] else None


def site_for(host, known):
    host = (host or "").lower().rstrip(".")
    parts = host.split(".")
    for i in range(len(parts) - 1):
        suffix = ".".join(parts[i:])
        if suffix in known["sites"]:
            return suffix, known["sites"][suffix]
    return None, None


def address_kind(ip):
    try:
        a = ipaddress.ip_address(ip)
    except ValueError:
        return "unknown"
    if a.is_loopback:
        return "loopback"
    if a.is_multicast:
        return "multicast"
    if a.is_link_local:
        return "link-local"
    if isinstance(a, ipaddress.IPv4Address) and a in ipaddress.ip_network("100.64.0.0/10"):
        return "cgnat"
    if any(a in n for n in LAN_NETS if n.version == a.version):
        return "lan"
    if not a.is_global:
        return "reserved"
    return "public"


def sentence(text):
    text = text.strip()
    return text if text.endswith((".", "!", "?")) else text + "."


def article(noun):
    return ("an " if noun[:1].lower() in "aeiou" else "a ") + noun


def duration(seconds):
    s = int(seconds)
    if s < 60:
        return f"{s} second{'s' if s != 1 else ''}"
    if s < 3600:
        m = s // 60
        return f"{m} minute{'s' if m != 1 else ''}"
    if s < 86400:
        h = s // 3600
        return f"{h} hour{'s' if h != 1 else ''}"
    d = s // 86400
    return f"{d} day{'s' if d != 1 else ''}"


def script_of(args):
    """The script an interpreter runs: its first argument that isn't an option."""
    rest = list(args[1:])
    while rest:
        a = rest.pop(0)
        if a in ("-c", "-e", "--eval"):
            return "inline code given on the command line"
        if a == "-m" and rest:
            return f"the {rest[0]} module"
        if a.startswith("-"):
            continue
        return a
    return None


def ancestors(conn):
    """[(path, pid)] from the parent up, without the process itself."""
    tree = [(p, pid) for p, pid in conn.get("process_tree") or []]
    if tree and tree[0][1] == conn.get("process_id"):
        tree = tree[1:]
    return tree


# ---------- the explanation ----------


def explain(conn, known, system=None, desktop=None):
    system = system or System()
    desktop = desktop or {}
    path = conn.get("process_path") or ""
    args = list(conn.get("process_args") or [])
    pid = conn.get("process_id") or 0
    uid = conn.get("user_id")
    host = conn.get("dst_host") or ""
    ip = conn.get("dst_ip") or ""
    port = conn.get("dst_port") or 0
    proto = (conn.get("protocol") or "").lower()
    if host == ip:
        host = ""

    exe_name = base(path)
    key = program_key(exe_name, known)
    prog = known["programs"].get(key, {}) if key else {}
    kind_id = prog.get("kind")
    flags = []  # (severity: "high" | "medium" | "info", text)
    advanced = []

    # --- the program ---
    package = None
    owner = system.owner(path) if path else None
    if owner:
        package = system.package(owner) or {"name": owner, "version": "", "description": "", "url": ""}
    unit = system.unit(pid) if pid else None
    unit_info = system.unit_info(*unit) if unit and unit[1].endswith(".service") else None
    age = system.age(pid) if pid else None
    live_exe = system.exe(pid) if pid else None

    flatpak = None
    if unit and unit[1].startswith("app-flatpak-"):
        flatpak = unit[1][len("app-flatpak-"):].rsplit("-", 1)[0]
    appimage = path.startswith("/tmp/.mount_")

    name = prog.get("name") or desktop.get("name") or exe_name or "An unknown program"
    if not kind_id:
        if unit and unit[0] == "system" and unit[1].endswith(".service"):
            kind_id = "system"
        elif desktop.get("name") or flatpak or appimage:
            kind_id = "app"
    kind = known["kinds"].get(kind_id) if kind_id else None

    what = prog.get("what")
    if not what and kind:
        what = article(kind["label"]).capitalize() + "."
    if desktop.get("description"):
        entry = sentence(desktop["description"])
        what = f"{what} {entry}" if what else entry
    if package and package["description"]:
        source = sentence(f"Installed by the system's package manager as “{package['name']}”: {package['description']}")
        what = f"{what} {source}" if what else source
    elif flatpak:
        what = (what + " " if what else "") + f"A Flatpak app ({flatpak}), running in its own sandbox."
    elif appimage:
        what = (what + " " if what else "") + "An AppImage: a self-contained app you downloaded and ran directly."
    if not what:
        what = "Nothing on this computer describes it: it's not from the package manager and not in Bahya Nireekshana's list of known programs."

    purpose = kind["purpose"] if kind else "Unknown. Look at its name, folder and what started it (below) to work out what it is."

    # --- interpreters: the script is what matters ---
    script = None
    if key and VERSIONED.sub(r"\1", key) in INTERPRETERS or exe_name in INTERPRETERS:
        script = script_of(args)
        if script:
            purpose = f"{purpose} Here it is running {script}."

    # --- who it's talking to ---
    akind = address_kind(ip)
    suffix, site = site_for(host, known) if host else (None, None)
    port_info = known["ports"].get(str(port))
    target = host or ip or "an unknown address"
    if akind == "loopback":
        talking = f"This same computer ({target}). Nothing leaves your machine."
    elif akind in ("lan", "link-local"):
        talking = f"A device on your own network ({target}), such as the router, a printer or another computer. It doesn't go out to the internet."
    elif akind == "multicast":
        talking = f"Every device on your local network at once ({target}): a shout to find printers, speakers or TVs. It doesn't leave your network."
    elif akind == "reserved":
        talking = f"{target}: a special-purpose address that isn't on the internet (documentation, testing or similar)."
    elif akind == "cgnat":
        talking = f"{target}: an address in the range used by Tailscale and by some internet providers."
    elif site:
        talking = f"{target}, which belongs to {site['owner']}: {site['what']}."
    elif host:
        talking = f"{target}. Bahya Nireekshana doesn't know who runs this site."
    else:
        talking = f"{target}, a bare internet address with no name, so it's hard to tell who runs it."
    if port_info:
        talking += f" The connection is {port_info['what']} ({proto.upper()} port {port}, {port_info['name']})."
    elif port:
        talking += f" It uses {proto.upper()} port {port}, which isn't a common one."

    # --- why now ---
    why = []
    tree = ancestors(conn)
    parents = [base(p) for p, _ in tree]
    unit_name = unit[1] if unit else ""
    triggered = (unit_info or {}).get("triggered_by", "")
    if triggered and ".timer" in triggered:
        why.append(f"It's a scheduled job: {triggered.split()[0]} starts it on its own, without anyone asking.")
    elif unit and unit[0] == "system" and unit_name.endswith(".service"):
        desc = (unit_info or {}).get("description")
        why.append(
            f"It runs in the background as the system service {unit_name}"
            + (f" (“{desc}”)" if desc else "")
            + ". Nobody had to click anything."
        )
    elif any(p in TERMINALS for p in parents):
        why.append("It was started from a terminal: you, or a script or command you ran, started it.")
    elif parents and parents[0] in SHELLS:
        why.append(f"A shell script started it (its parent is {parents[0]}).")
    elif parents:
        parent = parents[0]
        pkey = program_key(parent, known)
        pname = known["programs"][pkey]["name"] if pkey else parent
        if parent == "systemd":
            why.append("It was started by your session in the background, not by a click.")
        elif pkey != key:
            why.append(f"It was started by {pname}.")
    if unit_name.startswith("app-") and not why:
        why.append("It's an app opened in your desktop session.")
    if age is not None:
        if age < 15:
            why.append(f"It started {duration(age)} ago, so this is likely part of what it does on start-up.")
        else:
            why.append(
                f"It has been running for {duration(age)}; something it does now and then (a check, refresh, sync or update) needed the network just now."
            )
    elif pid:
        why.append("It finished before it could be looked at, which short commands often do.")
    why.append(
        "OpenSnitch asks because it has no saved answer yet for this program and destination."
    )

    # --- what happens after ---
    if_allow = kind["allow"] if kind else "The program can reach this address."
    if_deny = kind["deny"] if kind else "The program can't reach this address. If it needs it, a feature stops working; if not, nothing visible changes."
    if site and site.get("tracking"):
        if_deny = f"{site['owner']} gets no {site['what']} from this program. Usually nothing you use breaks."
    if akind in ("loopback",):
        if_deny += " Blocking connections inside your own computer often breaks programs in confusing ways."
    later = (
        "Your answer is kept for as long as the duration box says (\u201cforever\u201d means until you change it). "
        "Change or remove it any time in the Bahya Nireekshana widget, under Allowed & blocked, or in the OpenSnitch window."
    )

    # --- things to notice ---
    if live_exe and live_exe.endswith(" (deleted)"):
        flags.append(("high", "The program file was deleted after it started. Updates do this, but so does malware hiding its tracks."))
    if path.startswith(SCRATCH_DIRS) and not appimage:
        flags.append(("high", f"It runs from a temporary folder ({os.path.dirname(path)}), where installed software doesn't live."))
    if script and script.startswith(SCRATCH_DIRS):
        flags.append(("high", f"The script it runs ({script}) is in a temporary folder."))
    home = os.path.expanduser("~")
    if path.startswith(home + "/") and "/." in path[len(home):] and not path.startswith(
        (home + "/.local/", home + "/.cargo/", home + "/.bun/", home + "/.npm", home + "/.nvm/", home + "/.rustup/", home + "/.pyenv/", home + "/.deno/", home + "/.claude/")
    ):
        flags.append(("medium", "It runs from a hidden folder in your home directory."))
    if path and not owner and not flatpak and not appimage and not path.startswith(home + "/"):
        flags.append(("medium", "No package installed it, so nobody vouches for this file."))
    if uid == 0 and kind_id not in ("dns", "time", "network", "packages", "firmware", "vpn", "local", "system"):
        flags.append(("medium", "It runs as root (full control of the computer), which ordinary apps don't need."))
    if port in known.get("odd_ports", []):
        flags.append(("high", f"Port {port} is a default for remote-control and test tools."))
    if akind == "public" and not host:
        flags.append(("info", "The destination has no name, only a number. Apps usually connect by name."))
    if port == 80 and akind == "public":
        flags.append(("info", "The connection isn't encrypted."))
    if port == 25:
        flags.append(("medium", "Sending mail straight to a mail server is something spam bots do; mail apps use 465 or 587."))
    if site and site.get("tracking"):
        flags.append(("info", f"This is {site['what']} ({site['owner']}). Blocking it usually costs nothing."))
    if exe_name in ("nc", "ncat", "socat") and akind == "public":
        flags.append(("medium", f"{exe_name} is reaching the internet. That's fine if you are testing something yourself."))

    # --- verdict ---
    sev = {s for s, _ in flags}
    if "high" in sev:
        verdict = {
            "level": "caution",
            "label": "Be careful",
            "advice": "Deny unless you know exactly why this is happening. A wrong deny is easy to undo; a wrong allow may not be.",
        }
    elif "medium" in sev or not (prog or package or desktop.get("name") or flatpak):
        verdict = {
            "level": "check",
            "label": "Worth a look",
            "advice": "Allow if you recognise the program and expected it to go online now. If not, deny: you can change it later.",
        }
    else:
        verdict = {
            "level": "routine",
            "label": "Looks routine",
            "advice": "A known program doing its usual job. Allowing it is normally fine.",
        }

    label = f"{name}, {article(kind['label'])}," if kind else name
    dest = site["owner"] if site else (host or ip)
    if akind in ("lan", "link-local", "multicast"):
        dest = "a device on your network"
    elif akind == "loopback":
        dest = "another program on this computer"
    headline = f"{label} wants to reach {dest}"
    headline += f" for {port_info['what'].split(':')[0]}." if port_info else "."

    plain = [
        ("What is it", what),
        ("What it's for", purpose),
        ("Who it's talking to", talking),
        ("Why now", " ".join(why)),
        ("If you allow", if_allow),
        ("If you deny", if_deny),
        ("Changing your mind", later),
    ]
    if flags:
        plain.append(("Things to notice", " ".join(t for _, t in flags)))

    # --- the advanced view ---
    advanced.append(("Program", path or "unknown"))
    if live_exe and live_exe != path:
        advanced.append(("Running file", live_exe))
    if args:
        advanced.append(("Command line", " ".join(args)))
    if script:
        advanced.append(("Script", script))
    if conn.get("process_cwd"):
        advanced.append(("Started in folder", conn["process_cwd"]))
    advanced.append(("Process ID", str(pid)))
    if uid is not None:
        advanced.append(("User ID", str(uid)))
    if age is not None:
        advanced.append(("Running for", duration(age)))
    if package:
        advanced.append(("Package", f"{package['name']} {package['version']}".strip()))
        if package["url"]:
            advanced.append(("Project page", package["url"]))
    elif flatpak:
        advanced.append(("Flatpak app", flatpak))
    else:
        advanced.append(("Package", "none (not installed by pacman)"))
    if unit:
        advanced.append(("systemd unit", f"{unit_name} ({unit[0]})"))
    if triggered:
        advanced.append(("Triggered by", triggered))
    if tree:
        advanced.append(("Started by", " ← ".join(f"{base(p)} [{q}]" for p, q in tree)))
    advanced.append(("Destination", f"{host + ' ' if host else ''}{ip}".strip()))
    advanced.append(("Address type", {
        "loopback": "this computer (loopback)",
        "lan": "your local network",
        "link-local": "your local network (link-local)",
        "multicast": "local multicast",
        "cgnat": "carrier-grade NAT / Tailscale range",
        "reserved": "reserved (not routed on the internet)",
        "public": "the internet",
    }.get(akind, "unknown")))
    if site:
        advanced.append(("Site owner", f"{site['owner']} (matched {suffix})"))
    advanced.append(("Protocol and port", f"{proto.upper()} {port}" + (f" ({port_info['name']})" if port_info else "")))
    md5 = (conn.get("process_checksums") or {}).get("md5")
    if md5:
        advanced.append(("MD5 of the program", md5))

    return {"headline": headline, "verdict": verdict, "plain": plain, "advanced": advanced}


# ---------- rich text for the prompt (every value escaped: it comes from the connection) ----------

COLOURS = {"routine": "#2e9d48", "check": "#d08a00", "caution": "#e0453a"}


def plain_html(result):
    v = result["verdict"]
    colour = COLOURS[v["level"]]
    parts = [
        f"<p><b style='color:{colour}'>● {html.escape(v['label'])}</b> — {html.escape(v['advice'])}</p>",
        f"<p><b>{html.escape(result['headline'])}</b></p>",
    ]
    for title, text in result["plain"]:
        parts.append(f"<p><b>{html.escape(title)}</b><br>{html.escape(text)}</p>")
    return "".join(parts)


def advanced_html(result):
    rows = "".join(
        f"<tr><td style='padding-right:10px'><b>{html.escape(k)}</b></td><td>{html.escape(v)}</td></tr>"
        for k, v in result["advanced"]
    )
    return f"<table cellspacing='2'>{rows}</table>"


def conn_from_proto(con):
    """The fields explain() uses, from an OpenSnitch protobuf Connection."""
    return {
        "protocol": con.protocol,
        "dst_ip": con.dst_ip,
        "dst_host": con.dst_host,
        "dst_port": con.dst_port,
        "user_id": con.user_id,
        "process_id": con.process_id,
        "process_path": con.process_path,
        "process_args": list(con.process_args),
        "process_cwd": con.process_cwd,
        "process_checksums": dict(con.process_checksums),
        "process_tree": [(item.key, item.value) for item in con.process_tree],
    }


if __name__ == "__main__":
    # Explain a running process's connection from the command line:
    #   explain.py <pid> <host-or-ip> <port>
    import sys

    pid, dest, port = int(sys.argv[1]), sys.argv[2], int(sys.argv[3])
    try:
        ipaddress.ip_address(dest)
        ip, host = dest, ""
    except ValueError:
        ip, host = "", dest
    sys_ = System()
    exe = sys_.exe(pid) or ""
    with open(f"/proc/{pid}/cmdline", "rb") as f:
        cmd = [a.decode(errors="replace") for a in f.read().split(b"\0") if a]
    out = explain(
        {"protocol": "tcp", "dst_ip": ip, "dst_host": host, "dst_port": port, "user_id": os.getuid(),
         "process_id": pid, "process_path": exe.removesuffix(" (deleted)"), "process_args": cmd},
        load_known(), sys_,
    )
    print(out["headline"])
    print(f"[{out['verdict']['label']}] {out['verdict']['advice']}\n")
    for title, text in out["plain"]:
        print(f"{title}: {text}\n")
    for label, value in out["advanced"]:
        print(f"  {label}: {value}")
