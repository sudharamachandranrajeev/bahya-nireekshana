"""Tests for the OpenSnitch prompt explainer (opensnitch/nireekshana/explain.py), with
fake look-ups so nothing depends on this machine:
python3 -I -m unittest discover -s ~/Work/bahya-nireekshana/omarchy/tests
"""

import importlib.util
import os
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SOURCE = os.path.join(HERE, "..", "opensnitch", "nireekshana", "explain.py")

spec = importlib.util.spec_from_file_location("explain", SOURCE)
ex = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ex)
KNOWN = ex.load_known()


class FakeSystem:
    def __init__(self, owner=None, package=None, unit=None, unit_info=None, age=120.0, exe=None):
        self._owner, self._package, self._unit = owner, package, unit
        self._unit_info, self._age, self._exe = unit_info, age, exe

    def owner(self, path):
        return self._owner

    def package(self, name):
        return self._package

    def unit(self, pid):
        return self._unit

    def unit_info(self, scope, unit):
        return self._unit_info

    def age(self, pid):
        return self._age

    def exe(self, pid):
        return self._exe


CURL_PACKAGE = {"name": "curl", "version": "8.10.1-1", "description": "command line tool", "url": "https://curl.se"}


def conn(**over):
    c = {
        "protocol": "tcp",
        "dst_ip": "140.82.112.3",
        "dst_host": "api.github.com",
        "dst_port": 443,
        "user_id": 1000,
        "process_id": 4242,
        "process_path": "/usr/bin/curl",
        "process_args": ["curl", "https://api.github.com"],
        "process_cwd": "/home/me",
        "process_tree": [("/usr/bin/curl", 4242), ("/usr/bin/bash", 4000), ("/usr/bin/alacritty", 3900), ("/usr/lib/systemd/systemd", 1)],
    }
    c.update(over)
    return c


def sections(result):
    return dict(result["plain"])


class ExplainTest(unittest.TestCase):
    def test_known_program_from_a_package_is_routine(self):
        r = ex.explain(conn(), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE))
        self.assertEqual(r["verdict"]["level"], "routine")
        self.assertIn("curl", r["headline"])
        self.assertIn("GitHub", r["headline"])
        s = sections(r)
        self.assertIn("command line tool", s["What is it"])
        self.assertIn("GitHub", s["Who it's talking to"])
        self.assertIn("terminal", s["Why now"])
        self.assertIn("connection error", s["If you deny"])
        self.assertIn("Allowed & blocked", s["Changing your mind"])
        self.assertNotIn("Things to notice", s)

    def test_program_in_a_temporary_folder_needs_care(self):
        r = ex.explain(conn(process_path="/tmp/upd", process_args=["/tmp/upd"]), KNOWN, FakeSystem())
        self.assertEqual(r["verdict"]["level"], "caution")
        self.assertIn("temporary folder", sections(r)["Things to notice"])

    def test_deleted_program_file_needs_care(self):
        r = ex.explain(conn(), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE, exe="/usr/bin/curl (deleted)"))
        self.assertEqual(r["verdict"]["level"], "caution")
        self.assertIn("deleted", sections(r)["Things to notice"])

    def test_remote_control_port_needs_care(self):
        r = ex.explain(conn(dst_port=4444, dst_host="", dst_ip="45.33.32.156"), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE))
        self.assertEqual(r["verdict"]["level"], "caution")
        notice = sections(r)["Things to notice"]
        self.assertIn("4444", notice)
        self.assertIn("no name", notice)

    def test_unknown_program_is_worth_a_look(self):
        r = ex.explain(conn(process_path="/opt/thing/thing", process_args=["thing"]), KNOWN, FakeSystem())
        self.assertEqual(r["verdict"]["level"], "check")
        self.assertIn("Nothing on this computer describes it", sections(r)["What is it"])
        self.assertIn("No package installed it", sections(r)["Things to notice"])

    def test_script_runner_names_the_script(self):
        args = ["python3", "-u", "/tmp/payload.py"]
        r = ex.explain(conn(process_path="/usr/bin/python3.14", process_args=args), KNOWN, FakeSystem(owner="python"))
        self.assertIn("/tmp/payload.py", sections(r)["What it's for"])
        self.assertEqual(r["verdict"]["level"], "caution")
        self.assertIn(("Script", "/tmp/payload.py"), r["advanced"])

    def test_scheduled_job(self):
        r = ex.explain(
            conn(process_path="/usr/bin/fwupdmgr", process_args=["fwupdmgr", "refresh"], user_id=0,
                 process_tree=[("/usr/bin/fwupdmgr", 4242), ("/usr/lib/systemd/systemd", 1)]),
            KNOWN,
            FakeSystem(owner="fwupd", unit=("system", "fwupd-refresh.service"),
                       unit_info={"description": "Refresh fwupd metadata", "triggered_by": "fwupd-refresh.timer"}),
        )
        why = sections(r)["Why now"]
        self.assertIn("scheduled job", why)
        self.assertIn("fwupd-refresh.timer", why)
        self.assertEqual(r["verdict"]["level"], "routine")

    def test_background_service_names_its_unit(self):
        r = ex.explain(
            conn(process_path="/usr/lib/systemd/systemd-resolved", process_args=[], dst_host="one.one.one.one",
                 dst_ip="1.1.1.1", dst_port=853, user_id=977, process_tree=[]),
            KNOWN,
            FakeSystem(owner="systemd", unit=("system", "systemd-resolved.service"),
                       unit_info={"description": "Network Name Resolution", "triggered_by": ""}),
        )
        self.assertIn("systemd-resolved.service", sections(r)["Why now"])
        self.assertIn("Network Name Resolution", sections(r)["Why now"])
        self.assertIn("almost nothing on the internet will work", sections(r)["If you deny"])
        self.assertIn("encrypted name lookup", r["headline"])

    def test_root_app_is_flagged(self):
        r = ex.explain(conn(user_id=0), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE))
        self.assertEqual(r["verdict"]["level"], "check")
        self.assertIn("root", sections(r)["Things to notice"])

    def test_tracker_deny_costs_nothing(self):
        r = ex.explain(conn(process_path="/usr/lib/firefox/firefox", process_args=["firefox"], dst_host="www.google-analytics.com"),
                       KNOWN, FakeSystem(owner="firefox"))
        self.assertIn("Usually nothing you use breaks", sections(r)["If you deny"])
        self.assertIn("visitor tracking", sections(r)["Things to notice"])

    def test_destinations(self):
        cases = {
            "127.0.0.1": "This same computer",
            "192.168.1.1": "your own network",
            "fe80::1": "your own network",
            "224.0.0.251": "Every device on your local network",
            "100.101.102.103": "Tailscale",
            "203.0.113.9": "special-purpose address",
        }
        for ip, words in cases.items():
            r = ex.explain(conn(dst_ip=ip, dst_host=""), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE))
            self.assertIn(words, sections(r)["Who it's talking to"], ip)

    def test_unknown_site_and_port(self):
        r = ex.explain(conn(dst_host="example.net", dst_port=7777), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE))
        talking = sections(r)["Who it's talking to"]
        self.assertIn("doesn't know who runs this site", talking)
        self.assertIn("port 7777", talking)

    def test_short_lived_process(self):
        r = ex.explain(conn(), KNOWN, FakeSystem(owner="curl", package=CURL_PACKAGE, age=None))
        self.assertIn("finished before it could be looked at", sections(r)["Why now"])

    def test_html_is_escaped(self):
        evil = "<img src=x onerror=alert(1)>"
        r = ex.explain(conn(process_path="/opt/" + evil, process_args=[evil], dst_host=evil + ".com"), KNOWN, FakeSystem())
        for text in (ex.plain_html(r), ex.advanced_html(r)):
            self.assertNotIn("<img", text)
            self.assertIn("&lt;img", text)


class HelpersTest(unittest.TestCase):
    def test_site_matches_longest_suffix(self):
        self.assertEqual(ex.site_for("aur.archlinux.org", KNOWN)[0], "aur.archlinux.org")
        self.assertEqual(ex.site_for("mirror.archlinux.org", KNOWN)[0], "archlinux.org")
        self.assertEqual(ex.site_for("notgithub.com", KNOWN), (None, None))
        self.assertEqual(ex.site_for("com", KNOWN), (None, None))

    def test_script_of(self):
        self.assertEqual(ex.script_of(["python3", "-u", "x.py", "--flag"]), "x.py")
        self.assertEqual(ex.script_of(["python3", "-m", "http.server"]), "the http.server module")
        self.assertEqual(ex.script_of(["bash", "-c", "curl x | sh"]), "inline code given on the command line")
        self.assertIsNone(ex.script_of(["node"]))

    def test_unit_from_cgroup(self):
        self.assertEqual(ex.unit_from_cgroup("0::/system.slice/fwupd-refresh.service\n"), ("system", "fwupd-refresh.service"))
        self.assertEqual(
            ex.unit_from_cgroup("0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-firefox@1.service\n"),
            ("user", "app-firefox@1.service"),
        )
        self.assertIsNone(ex.unit_from_cgroup("0::/\n"))

    def test_package_and_age_from_files(self):
        with tempfile.TemporaryDirectory() as d:
            db = os.path.join(d, "local", "curl-8.10.1-1")
            os.makedirs(db)
            with open(os.path.join(db, "desc"), "w") as f:
                f.write("%NAME%\ncurl\n\n%VERSION%\n8.10.1-1\n\n%DESC%\ncommand line tool\n\n%URL%\nhttps://curl.se\n")
            os.makedirs(os.path.join(d, "local", "curl-extra-1-1"))
            proc = os.path.join(d, "proc")
            os.makedirs(os.path.join(proc, "42"))
            tick = os.sysconf("SC_CLK_TCK")
            with open(os.path.join(proc, "uptime"), "w") as f:
                f.write("1000.00 5000.00\n")
            fields = ["S"] + ["0"] * 18 + [str(900 * tick)]
            with open(os.path.join(proc, "42", "stat"), "w") as f:
                f.write("42 (we ird) name) " + " ".join(fields) + " 0 0\n")
            s = ex.System(proc=proc, pacman_db=os.path.join(d, "local"))
            self.assertEqual(s.package("curl")["description"], "command line tool")
            self.assertIsNone(s.package("wget"))
            self.assertAlmostEqual(s.age(42), 100.0)
            self.assertIsNone(s.age(43))

    def test_known_json_is_consistent(self):
        for key, prog in KNOWN["programs"].items():
            self.assertIn(prog["kind"], KNOWN["kinds"], key)
        for kind in KNOWN["kinds"].values():
            for field in ("label", "purpose", "allow", "deny"):
                self.assertTrue(kind[field])
        for port in KNOWN["ports"]:
            self.assertTrue(port.isdigit())


if __name__ == "__main__":
    unittest.main()
