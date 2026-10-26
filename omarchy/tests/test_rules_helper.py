"""Tests for bin/nireekshana-rules, run unprivileged against temp directories:
python3 -I -m unittest discover -s ~/Work/bahya-nireekshana/omarchy/tests
"""

import importlib.machinery
import importlib.util
import json
import os
import tempfile
import unittest

HELPER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "nireekshana-rules")


def load_helper():
    loader = importlib.machinery.SourceFileLoader("nireekshana_rules", HELPER)
    spec = importlib.util.spec_from_loader("nireekshana_rules", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def rule(name, action="allow", path="/usr/bin/curl"):
    return {
        "created": "2026-10-12T00:00:00Z", "updated": "2026-10-12T00:00:00Z",
        "name": name, "enabled": True, "precedence": False, "action": action, "duration": "always",
        "operator": {"type": "simple", "operand": "process.path", "sensitive": False, "data": path, "list": []},
    }


class HelperTest(unittest.TestCase):
    def setUp(self):
        self.h = load_helper()
        self.tmp = tempfile.TemporaryDirectory()
        root = self.tmp.name
        self.h.RULES = os.path.join(root, "rules")
        self.h.LISTS = os.path.join(root, "lists")
        self.h.EXPORT = os.path.join(root, "run", "rules.json")
        self.h.EXPORT_GROUP = "no-such-group-nireekshana-test"
        os.makedirs(self.h.RULES)
        for list_id in self.h.LIST_KINDS:
            os.makedirs(os.path.join(self.h.LISTS, list_id))
            with open(os.path.join(self.h.LISTS, list_id, "list.txt"), "w") as f:
                f.write("# comment\n#\n")

    def tearDown(self):
        self.tmp.cleanup()

    def write_rule(self, data):
        with open(os.path.join(self.h.RULES, data["name"] + ".json"), "w") as f:
            json.dump(data, f)

    def read_list(self, list_id):
        with open(os.path.join(self.h.LISTS, list_id, "list.txt")) as f:
            return f.read()

    # ---------- rules ----------

    def test_set_action_renames_prefixed_rule(self):
        self.write_rule(rule("allow-always-simple-usr-bin-curl"))
        self.h.set_action("allow-always-simple-usr-bin-curl.json", "deny")
        self.assertEqual(sorted(os.listdir(self.h.RULES)), ["deny-always-simple-usr-bin-curl.json"])
        with open(os.path.join(self.h.RULES, "deny-always-simple-usr-bin-curl.json")) as f:
            data = json.load(f)
        self.assertEqual(data["action"], "deny")
        self.assertEqual(data["name"], "deny-always-simple-usr-bin-curl")
        self.assertEqual(data["operator"]["data"], "/usr/bin/curl")
        self.assertNotEqual(data["updated"], "2026-10-12T00:00:00Z")

    def test_set_action_keeps_custom_names_in_place(self):
        self.write_rule(rule("my-curl-rule"))
        self.h.set_action("my-curl-rule.json", "deny")
        with open(os.path.join(self.h.RULES, "my-curl-rule.json")) as f:
            self.assertEqual(json.load(f)["action"], "deny")

    def test_set_action_refuses_clobbering(self):
        self.write_rule(rule("allow-always-x"))
        self.write_rule(rule("deny-always-x", action="deny"))
        with self.assertRaises(self.h.Refused):
            self.h.set_action("allow-always-x.json", "deny")

    def test_rule_names_are_confined(self):
        self.write_rule(rule("000-nireekshana-block-domains"))
        for bad in ("../x.json", "x", ".hidden.json", "000-nireekshana-block-domains.json", "missing.json"):
            with self.assertRaises(self.h.Refused, msg=bad):
                self.h.delete(bad)
        with self.assertRaises(self.h.Refused):
            self.h.set_action("allow-always-x.json", "reject")

    def test_delete(self):
        self.write_rule(rule("deny-always-simple-usr-bin-cliamp", action="deny"))
        self.h.delete("deny-always-simple-usr-bin-cliamp.json")
        self.assertEqual(os.listdir(self.h.RULES), [])

    # ---------- lists ----------

    def test_list_add_domain_normalizes_and_dedupes(self):
        self.h.list_add("block-domains", "  Ads.Example.COM. ")
        self.h.list_add("block-domains", "ads.example.com")
        self.assertEqual(self.read_list("block-domains"), "# comment\n#\n0.0.0.0 ads.example.com\n")

    def test_list_add_moves_between_block_and_allow(self):
        self.h.list_add("allow-domains", "example.org")
        self.h.list_add("block-domains", "example.org")
        self.assertNotIn("example.org", self.read_list("allow-domains"))
        self.assertIn("0.0.0.0 example.org", self.read_list("block-domains"))

    def test_list_add_network(self):
        self.h.list_add("block-nets", "203.0.113.7")
        self.h.list_add("block-nets", "198.51.100.9/24")
        self.h.list_add("allow-nets", "2001:db8::1")
        self.assertIn("203.0.113.7/32\n198.51.100.0/24\n", self.read_list("block-nets"))
        self.assertIn("2001:db8::1/128", self.read_list("allow-nets"))

    def test_list_add_rejects_bad_entries(self):
        for list_id, bad in (("block-domains", "*.example.com"), ("block-domains", "not a domain"),
                             ("block-domains", "-bad.com"), ("block-nets", "999.1.1.1"),
                             ("block-nets", "0.0.0.0/0"), ("nope", "example.com")):
            with self.assertRaises(self.h.Refused, msg=bad):
                self.h.list_add(list_id, bad)

    def test_list_remove_keeps_comments(self):
        self.h.list_add("block-domains", "a.example.com")
        self.h.list_add("block-domains", "b.example.com")
        self.h.list_remove("block-domains", "A.example.com")
        self.assertEqual(self.read_list("block-domains"), "# comment\n#\n0.0.0.0 b.example.com\n")

    def test_missing_list_file_is_refused(self):
        os.remove(os.path.join(self.h.LISTS, "allow-nets", "list.txt"))
        with self.assertRaises(self.h.Refused):
            self.h.list_add("allow-nets", "10.0.0.0/8")

    # ---------- export ----------

    def test_export(self):
        self.write_rule(rule("allow-always-simple-usr-bin-telegram", path="/usr/bin/telegram"))
        with open(os.path.join(self.h.RULES, "broken.json"), "w") as f:
            f.write("{")
        self.h.list_add("block-domains", "tracker.example.com")
        os.remove(os.path.join(self.h.LISTS, "allow-nets", "list.txt"))
        self.h.export()
        with open(self.h.EXPORT) as f:
            data = json.load(f)
        by_file = {r["file"]: r for r in data["rules"]}
        self.assertEqual(by_file["allow-always-simple-usr-bin-telegram.json"]["operator"]["data"], "/usr/bin/telegram")
        self.assertIn("error", by_file["broken.json"])
        self.assertEqual(data["lists"]["block-domains"], ["tracker.example.com"])
        self.assertIsNone(data["lists"]["allow-nets"])
        self.assertEqual(oct(os.stat(self.h.EXPORT).st_mode & 0o777), "0o644")

    def test_main_usage_and_privileges(self):
        self.assertEqual(self.h.main([]), 2)
        self.assertEqual(self.h.main(["delete"]), 2)
        self.assertEqual(self.h.main(["rm", "-rf"]), 2)
        if os.geteuid() != 0:
            self.assertEqual(self.h.main(["export"]), 1)


if __name__ == "__main__":
    unittest.main()
