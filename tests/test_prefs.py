"""Unit tests for lib/prefs.py (run with: python3 -m unittest tests/test_prefs.py)."""

import os
import plistlib
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "lib"))

import prefs  # noqa: E402


class SanitizeTest(unittest.TestCase):
    def test_global_and_app_deny_lists_remove_keys(self):
        live = {
            "wdsAuthToken": "x",
            "NSWindow Frame Main": "0 0 1 1",
            "NSWindowFrameMain": "0 0 1 1",
            "SUFeedURL": "https://example.invalid",
            "NotchBar.cachedLatitude": 1.0,
            "MenuBarStyle": 2,
            "Profiles": {"a": 1},
        }
        self.assertEqual(
            prefs.sanitize(live, ["NotchBar.cached*"]),
            {"MenuBarStyle": 2, "Profiles": {"a": 1}},
        )

    def test_overlay_keeps_denied_live_keys_and_replaces_the_rest(self):
        full = {"wdsAuthToken": "local", "A": 1, "B": 2}
        merged = {"A": 9, "C": 3}
        self.assertEqual(
            prefs.overlay(full, merged, []),
            {"wdsAuthToken": "local", "A": 9, "C": 3},
        )


class MergeTest(unittest.TestCase):
    def test_one_sided_changes_are_taken(self):
        base = {"a": 1, "b": 1, "c": 1}
        incoming = {"a": 2, "b": 1, "c": 1, "new_remote": 1}
        live = {"a": 1, "b": 3, "new_local": 1}  # c deleted locally
        merged, conflicts = prefs.merge3(base, incoming, live)
        self.assertEqual(merged, {"a": 2, "b": 3, "new_local": 1, "new_remote": 1})
        self.assertEqual(conflicts, [])

    def test_both_changed_differently_keeps_live_and_reports(self):
        merged, conflicts = prefs.merge3({"a": 1}, {"a": 2}, {"a": 3})
        self.assertEqual(merged, {"a": 3})
        self.assertEqual(conflicts, ["a"])

    def test_both_changed_identically_is_not_a_conflict(self):
        merged, conflicts = prefs.merge3({"a": 1}, {"a": 2}, {"a": 2})
        self.assertEqual((merged, conflicts), ({"a": 2}, []))

    def test_remote_deletion_applies_when_unchanged_locally(self):
        merged, conflicts = prefs.merge3({"a": 1, "b": 1}, {"b": 1}, {"a": 1, "b": 1})
        self.assertEqual((merged, conflicts), ({"b": 1}, []))

    def test_restore_prefers_incoming_on_a_new_machine(self):
        self.assertEqual(prefs.restore({"a": 2}, {"a": 1, "b": 1}), {"a": 2, "b": 1})


class LocalChangesTest(unittest.TestCase):
    def test_keys_changed_only_here_are_added_to_incoming(self):
        base = {"a": 1, "b": 1, "c": 1}
        incoming = {"a": 2, "b": 1, "c": 1}
        live = {"a": 1, "b": 5, "d": 9}
        self.assertEqual(prefs.local_changes(base, incoming, live), {"a": 2, "b": 5, "d": 9})

    def test_keys_changed_on_both_sides_stay_incoming_for_the_merge(self):
        base, incoming, live = {"a": 1}, {"a": 2}, {"a": 3}
        self.assertEqual(prefs.local_changes(base, incoming, live), {"a": 2})


class DomainTest(unittest.TestCase):
    """Domain.tick with the cfprefsd and app calls replaced by fakes."""

    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.tracked = os.path.join(self.dir, "dev.dotfiles.test.x.plist")
        self.live = {"Theme": "dark"}
        self.pid = None
        self.originals = {n: getattr(prefs, n) for n in ("read_domain", "write_domain", "app_pid", "notify")}
        prefs.read_domain = lambda domain: dict(self.live)
        prefs.write_domain = lambda domain, values: self.live.clear() or self.live.update(values)
        prefs.app_pid = lambda bundle_id: self.pid
        prefs.notify = lambda title, message: None
        spec = {"id": "x", "domain": "dev.dotfiles.test.x", "reload": "next-launch", "file": self.tracked}
        self.domain = prefs.Domain(spec, self.dir)
        self.domain.export()

    def tearDown(self):
        for name, value in self.originals.items():
            setattr(prefs, name, value)

    def test_a_copy_pulled_during_export_is_not_overwritten(self):
        pulled = {"Theme": "light"}

        def read_while_mise_pulls(domain):
            prefs.write_plist_file(self.tracked, pulled)
            return {"Theme": "blue"}

        prefs.read_domain = read_while_mise_pulls
        self.assertEqual(self.domain.tick(lambda m: None), "changed")
        self.assertEqual(prefs.read_plist_file(self.tracked), pulled)

    def test_denied_keys_in_an_incoming_copy_are_never_applied(self):
        self.domain.deny = ("PrefsCustomFolder",)
        prefs.write_plist_file(self.tracked, {"Theme": "light", "PrefsCustomFolder": "/tmp/evil", "SUFeedURL": "x"})
        self.assertEqual(self.domain.tick(lambda m: None), "applied")
        self.assertEqual(self.live, {"Theme": "light"})

    def test_local_edits_keep_flowing_out_while_an_incoming_change_waits(self):
        self.pid = 42  # the app is running, so the incoming change waits
        prefs.write_plist_file(self.tracked, {"Theme": "dark", "Font": 14})
        self.live["Size"] = 2
        self.assertEqual(self.domain.tick(lambda m: None), "pending")
        self.assertEqual(prefs.read_plist_file(self.tracked), {"Theme": "dark", "Font": 14, "Size": 2})
        self.assertNotIn("Font", self.live)
        self.pid = None  # the app quit
        self.assertEqual(self.domain.tick(lambda m: None), "applied")
        self.assertEqual(self.live, {"Theme": "dark", "Font": 14, "Size": 2})


class FileTest(unittest.TestCase):
    def test_write_plist_file_is_private_sorted_and_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = os.path.join(tmp, "sub", "x.plist")
            self.assertTrue(prefs.write_plist_file(path, {"b": 1, "a": 2}))
            self.assertFalse(prefs.write_plist_file(path, {"a": 2, "b": 1}))
            self.assertEqual(os.stat(path).st_mode & 0o777, 0o600)
            with open(path, "rb") as handle:
                data = handle.read()
            self.assertLess(data.index(b"<key>a</key>"), data.index(b"<key>b</key>"))
            self.assertEqual(plistlib.loads(data), {"a": 2, "b": 1})

    def test_read_plist_file_missing_is_none(self):
        self.assertIsNone(prefs.read_plist_file("/nonexistent/x.plist"))


if __name__ == "__main__":
    unittest.main()
