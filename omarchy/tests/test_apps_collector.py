"""Tests for bin/nireekshana-apps, the per-app usage counter, without nethogs or root:
python3 -I -m unittest discover -s ~/Work/bahya-nireekshana/omarchy/tests
"""

import importlib.machinery
import importlib.util
import json
import os
import tempfile
import unittest

COLLECTOR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "nireekshana-apps")


def load_collector():
    loader = importlib.machinery.SourceFileLoader("nireekshana_apps", COLLECTOR)
    spec = importlib.util.spec_from_loader("nireekshana_apps", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


apps = load_collector()

ROUTE = """Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT
wg0\t00000000\t00000000\t0001\t0\t0\t50\t00000000\t0\t0\t0
enp3s0\t00000000\t0101A8C0\t0003\t0\t0\t100\t00000000\t0\t0\t0
wlan0\t00000000\t0101A8C0\t0003\t0\t0\t600\t00000000\t0\t0\t0
wlan0\t0001A8C0\t00000000\t0001\t0\t0\t600\t00FFFFFF\t0\t0\t0
"""


class ParseTest(unittest.TestCase):
    def test_trace_lines(self):
        self.assertEqual(
            apps.parse_line("/usr/lib/firefox/firefox/4242/1000\t1200\t56000\n"),
            ("/usr/lib/firefox/firefox", "4242", 1200, 56000),
        )
        self.assertEqual(apps.parse_line("unknown TCP/0/0\t10\t20"), ("unknown TCP", "0", 10, 20))
        self.assertIsNone(apps.parse_line("Refreshing:"))
        self.assertIsNone(apps.parse_line("garbage\tx\ty"))

    def test_names(self):
        self.assertEqual(apps.app_name("/usr/lib/firefox/firefox"), "firefox")
        self.assertEqual(apps.app_name("/usr/bin/python3 /opt/tool.py"), "python3")
        self.assertEqual(apps.app_name("unknown TCP"), "Unknown (system)")

    def test_default_route_skips_tunnels_and_takes_the_lowest_metric(self):
        self.assertEqual(apps.default_kind(ROUTE), "ethernet")
        self.assertEqual(apps.default_kind(ROUTE.replace("enp3s0\t00000000", "enp3s0\t0002A8C0")), "wifi")
        self.assertEqual(apps.default_kind("Iface\tDestination\n"), "other")


class CounterTest(unittest.TestCase):
    def test_growth_is_counted_once(self):
        c = apps.Counter()
        c.refresh()
        c.take("/usr/bin/curl", "10", 100, 1000, "wifi", "2026-10-26")
        c.refresh()
        c.take("/usr/bin/curl", "10", 150, 3000, "wifi", "2026-10-26")
        c.take("/usr/bin/curl", "11", 5, 5, "wifi", "2026-10-26")
        self.assertEqual(c.days["2026-10-26"][("/usr/bin/curl", "wifi")], [3005, 155])

    def test_kind_and_day_split_the_counts(self):
        c = apps.Counter()
        c.refresh()
        c.take("/usr/bin/curl", "10", 100, 100, "wifi", "2026-10-25")
        c.refresh()
        c.take("/usr/bin/curl", "10", 300, 300, "ethernet", "2026-10-26")
        self.assertEqual(c.days["2026-10-25"][("/usr/bin/curl", "wifi")], [100, 100])
        self.assertEqual(c.days["2026-10-26"][("/usr/bin/curl", "ethernet")], [200, 200])

    def test_an_ended_process_starts_again_from_nothing(self):
        c = apps.Counter()
        c.refresh()
        c.take("/usr/bin/curl", "10", 100, 100, "wifi", "2026-10-26")
        c.refresh()  # pid 10 is gone from this block
        c.refresh()
        c.take("/usr/bin/curl", "10", 40, 40, "wifi", "2026-10-26")
        self.assertEqual(c.days["2026-10-26"][("/usr/bin/curl", "wifi")], [140, 140])

    def test_old_days_are_dropped(self):
        c = apps.Counter({"2025-01-01": {("a", "wifi"): [1, 1]}, "2026-10-26": {("a", "wifi"): [1, 1]}})
        c.prune("2026-10-26")
        self.assertEqual(list(c.days), ["2026-10-26"])


class FileTest(unittest.TestCase):
    def test_save_and_load_round_trip(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "state", "apps.json")
            c = apps.Counter()
            c.refresh()
            c.take("/usr/lib/firefox/firefox", "1", 10, 20, "wifi", "2026-10-26")
            apps.save(c, path)
            self.assertEqual(os.stat(path).st_mode & 0o777, 0o644)
            with open(path) as f:
                data = json.load(f)
            self.assertEqual(data["version"], 1)
            self.assertEqual(
                data["days"]["2026-10-26"],
                [{"app": "/usr/lib/firefox/firefox", "name": "firefox", "kind": "wifi", "rx": 20, "tx": 10}],
            )
            again = apps.load(path)
            self.assertEqual(again.days, c.days)

    def test_a_broken_file_starts_afresh(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "apps.json")
            with open(path, "w") as f:
                f.write("{not json")
            self.assertEqual(apps.load(path).days, {})


if __name__ == "__main__":
    unittest.main()
