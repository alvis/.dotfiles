"""Sanitized macOS preference export and three-way import for mise history.

mise tracks a sanitized XML copy of each enrolled preference domain at
``~/.config/dotfiles/prefs/<domain>.plist``. This module keeps that copy and
the live domain in step:

* local change: the live domain differs from the last synced snapshot (the
  *base*), so the sanitized copy is rewritten and mise saves and pushes it;
* incoming change: the tracked copy differs from the base because mise pulled
  another machine's version, so it is merged key by key into the live domain
  with ``defaults import`` while the application is not running.

Runs on the /usr/bin/python3 (3.9) that ships with the Xcode Command Line
Tools; only the standard library is used.
"""

import argparse
import fcntl
import fnmatch
import json
import os
import plistlib
import re
import signal
import subprocess
import sys
import tempfile
import time

# top-level keys that never leave a machine, for every application
GLOBAL_DENY = (
    "NSWindowFrame*",
    "NSWindow Frame*",
    "PMPrinting*",
    "WindowNumber",
    "NSNavPanel*",
    "NSSplitView*",
    "NSTableView*",
    "NSToolbar*",
    "NSOSPLast*",
    "NSStatusItem Visible*",
    "SU*",
    "*SecurityScopedBookmark*",
    "*Token*",
    "*token*",
    "*Secret*",
    "*secret*",
    "*Password*",
    "*password*",
    "*License*",
    "*license*",
    "*Licence*",
    "*licence*",
    "*Serial*",
    "*APIKey*",
    "*ApiKey*",
    "*apiKey*",
    "*Latitude*",
    "*latitude*",
    "*Longitude*",
    "*longitude*",
    "*LastCheck*",
    "*LastLaunch*",
    "NoSync*",
)

_ABSENT = object()


class PrefsError(Exception):
    """A preference domain could not be read or written."""


def is_denied(key, deny):
    """Return True when a top-level key must not be exported."""
    for pattern in GLOBAL_DENY + tuple(deny):
        if fnmatch.fnmatchcase(key, pattern):
            return True
    return False


def sanitize(prefs, deny):
    """Return the exportable subset of a preference dictionary."""
    return {key: value for key, value in prefs.items() if not is_denied(key, deny)}


def merge3(base, incoming, live):
    """Merge top-level keys; return (merged, conflicting_keys).

    A key changed on one side only takes that side. A key changed on both
    sides to different values keeps the live (this machine's) value and is
    reported, so the other version is never dropped silently: it stays in mise
    history and in the conflict log.
    """
    merged = {}
    conflicts = []
    for key in sorted(set(base) | set(incoming) | set(live)):
        b = base.get(key, _ABSENT)
        i = incoming.get(key, _ABSENT)
        l = live.get(key, _ABSENT)
        if i == b:
            chosen = l
        elif l == b or l == i:
            chosen = i
        else:
            chosen = l
            conflicts.append(key)
        if chosen is not _ABSENT:
            merged[key] = chosen
    return merged, conflicts


def local_changes(base, incoming, live):
    """The incoming copy plus keys changed only on this machine.

    Used while an incoming change waits for the app to quit: this Mac's own
    edits keep flowing out, and keys changed on both sides stay as incoming
    until the merge, which then detects and reports them.
    """
    merged = dict(incoming)
    for key in set(base) | set(live):
        b = base.get(key, _ABSENT)
        l = live.get(key, _ABSENT)
        if incoming.get(key, _ABSENT) == b and l != b:
            if l is _ABSENT:
                merged.pop(key, None)
            else:
                merged[key] = l
    return merged


def restore(incoming, live):
    """First application on a machine with no synced base: incoming wins."""
    merged = dict(live)
    merged.update(incoming)
    return merged


def overlay(live_full, merged_sanitized, deny):
    """Replace the exportable part of the full live domain with merged values."""
    result = {key: value for key, value in live_full.items() if is_denied(key, deny)}
    result.update(merged_sanitized)
    return result


def _run(argv, check=True):
    proc = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and proc.returncode != 0:
        raise PrefsError("%s failed: %s" % (argv[0], proc.stderr.decode(errors="replace").strip()))
    return proc


def read_domain(domain):
    """Read a preference domain through cfprefsd (empty when it does not exist)."""
    proc = _run(["/usr/bin/defaults", "export", domain, "-"], check=False)
    if proc.returncode != 0 or not proc.stdout.strip():
        return {}
    try:
        return plistlib.loads(proc.stdout)
    except Exception as exc:  # malformed output from defaults
        raise PrefsError("cannot parse %s: %s" % (domain, exc))


def write_domain(domain, prefs):
    """Replace a preference domain through cfprefsd."""
    fd, path = tempfile.mkstemp(suffix=".plist")
    try:
        with os.fdopen(fd, "wb") as handle:
            plistlib.dump(prefs, handle, fmt=plistlib.FMT_BINARY)
        _run(["/usr/bin/defaults", "import", domain, path])
    finally:
        os.unlink(path)


def read_plist_file(path):
    """Read a plist file; None when it does not exist."""
    try:
        with open(path, "rb") as handle:
            return plistlib.load(handle)
    except FileNotFoundError:
        return None
    except Exception as exc:
        raise PrefsError("cannot parse %s: %s" % (path, exc))


def write_plist_file(path, prefs):
    """Write sorted XML atomically with mode 0600, only when contents change."""
    data = plistlib.dumps(prefs, fmt=plistlib.FMT_XML, sort_keys=True)
    try:
        with open(path, "rb") as handle:
            if handle.read() == data:
                return False
    except FileNotFoundError:
        pass
    directory = os.path.dirname(path)
    os.makedirs(directory, mode=0o700, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=directory, prefix=".tmp-", suffix=".plist")
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
        os.chmod(tmp, 0o600)
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise
    return True


def app_pid(bundle_id):
    """Return the pid of a running application, or None."""
    proc = _run(["/usr/bin/lsappinfo", "find", "bundleid=" + bundle_id], check=False)
    asn = proc.stdout.decode(errors="replace").strip().split(":", 1)
    if proc.returncode != 0 or len(asn) < 2 or not asn[1].strip():
        return None
    info = _run(["/usr/bin/lsappinfo", "info", "-only", "pid", proc.stdout.decode().strip()], check=False)
    match = re.search(r"pid\"?\s*=\s*(\d+)", info.stdout.decode(errors="replace"))
    return int(match.group(1)) if match else None


def stop_app(bundle_id, pid, timeout=10.0):
    """Terminate an application without Apple Events; True once it is gone."""
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        return True
    deadline = time.time() + timeout
    while time.time() < deadline:
        if app_pid(bundle_id) is None:
            return True
        time.sleep(0.25)
    return False


def start_app(bundle_id):
    _run(["/usr/bin/open", "-g", "-b", bundle_id], check=False)


def notify(title, message):
    script = "display notification %s with title %s" % (json.dumps(message), json.dumps(title))
    _run(["/usr/bin/osascript", "-e", script], check=False)


# cfprefsd serves the logged-in user's real domains whatever $HOME says, so a
# test run may only ever touch domains in this namespace
TEST_DOMAIN_PREFIX = "dev.dotfiles.test."


class Domain:
    """One enrolled preference domain."""

    def __init__(self, spec, state_dir):
        self.id = spec["id"]
        self.name = spec.get("name", self.id)
        self.domain = spec["domain"]
        if os.environ.get("DOTFILES_TEST_DOMAINS_ONLY") == "1" and not self.domain.startswith(TEST_DOMAIN_PREFIX):
            raise PrefsError("refusing real preference domain %s in a test run" % self.domain)
        self.bundle_id = spec.get("bundle_id") or self.domain
        self.reload = spec.get("reload", "restart-if-running")
        self.deny = tuple(spec.get("deny", ()))
        self.tracked = spec["file"]
        self.base_path = os.path.join(state_dir, self.domain + ".base.plist")
        self.pending_path = os.path.join(state_dir, self.domain + ".pending")

    def live(self):
        return sanitize(read_domain(self.domain), self.deny)

    def export(self):
        """Write the sanitized live domain to the tracked copy and the base."""
        live = self.live()
        write_plist_file(self.tracked, live)
        write_plist_file(self.base_path, live)
        return live

    def tick(self, log):
        """Reconcile one domain; returns a short status word."""
        raw = read_plist_file(self.tracked)
        if raw is None:
            return "untracked"
        # denied keys never come from another machine, whatever the copy holds
        incoming = sanitize(raw, self.deny)
        base = read_plist_file(self.base_path)
        if base is not None and incoming == base:
            if os.path.exists(self.pending_path):
                os.unlink(self.pending_path)
            live = self.live()
            if live == incoming:
                return "unchanged"
            if not replace_if_unchanged(self.tracked, raw, live):
                return "changed"  # mise wrote a newer copy meanwhile; the next tick applies it
            write_plist_file(self.base_path, live)
            return "exported"
        return self._apply(raw, incoming, base, log)

    def _apply(self, raw, incoming, base, log):
        pid = app_pid(self.bundle_id)
        restart = False
        if pid is not None:
            if self.reload == "restart-if-running":
                if not stop_app(self.bundle_id, pid):
                    log("%s: did not quit; will retry" % self.name)
                    return "waiting"
                restart = True
            else:
                if base is not None:
                    outgoing = local_changes(base, incoming, self.live())
                    if outgoing != incoming and replace_if_unchanged(self.tracked, raw, outgoing):
                        log("%s: exported local changes while an incoming change waits" % self.name)
                if not os.path.exists(self.pending_path):
                    open(self.pending_path, "w").close()
                    notify(
                        "Settings from another Mac",
                        "%s settings changed elsewhere; they apply after you quit %s."
                        % (self.name, self.name),
                    )
                return "pending"
        full = read_domain(self.domain)
        live = sanitize(full, self.deny)
        if base is None:
            merged, conflicts = restore(incoming, live), []
        else:
            merged, conflicts = merge3(base, incoming, live)
        write_domain(self.domain, overlay(full, merged, self.deny))
        final = sanitize(read_domain(self.domain), self.deny)
        # a copy mise wrote meanwhile stays; base moves on, so the next tick merges it
        replace_if_unchanged(self.tracked, raw, final)
        write_plist_file(self.base_path, final)
        if os.path.exists(self.pending_path):
            os.unlink(self.pending_path)
        if conflicts:
            log("%s: kept this Mac's value for %s" % (self.name, ", ".join(conflicts)))
            record_conflict(os.path.dirname(self.base_path), self, conflicts)
        if restart:
            start_app(self.bundle_id)
        return "applied"


def replace_if_unchanged(path, expected, value):
    """Write value unless the file no longer holds expected; True when written.

    mise may write a pulled copy between our read and our write; overwriting it
    would publish the old values again and revert the other Mac's change.
    """
    if read_plist_file(path) != expected:
        return False
    write_plist_file(path, value)
    return True


def record_conflict(state_dir, domain, keys):
    path = os.path.join(state_dir, "conflicts.jsonl")
    entry = {"time": int(time.time()), "app": domain.id, "domain": domain.domain, "keys": keys}
    with open(path, "a") as handle:
        handle.write(json.dumps(entry) + "\n")


def load_policy(path):
    with open(path) as handle:
        return json.load(handle)


def tick_all(policy, log):
    state_dir = policy["state_dir"]
    os.makedirs(state_dir, mode=0o700, exist_ok=True)
    lock_path = os.path.join(state_dir, "prefs.lock")
    with open(lock_path, "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return {}
        results = {}
        for spec in policy.get("apps", []):
            try:
                domain = Domain(spec, state_dir)
                results[domain.id] = domain.tick(log)
            except PrefsError as exc:
                results[spec.get("id", "?")] = "error"
                log("%s: %s" % (spec.get("name", spec.get("id", "?")), exc))
        return results


def main(argv=None):
    parser = argparse.ArgumentParser(prog="dotfiles prefs")
    sub = parser.add_subparsers(dest="command", required=True)

    exp = sub.add_parser("export", help="write a sanitized copy of one domain")
    exp.add_argument("--policy", required=True)
    exp.add_argument("--app", required=True)

    keys = sub.add_parser("keys", help="list exported and denied keys of a domain")
    keys.add_argument("--policy", required=True)
    keys.add_argument("--app", required=True)

    tick = sub.add_parser("tick", help="reconcile every enrolled domain once")
    tick.add_argument("--policy", required=True)

    args = parser.parse_args(argv)

    def log(message):
        sys.stderr.write("dotfiles prefs: %s\n" % message)
        sys.stderr.flush()

    if args.command in ("export", "keys"):
        policy = load_policy(args.policy)
        specs = [spec for spec in policy.get("apps", []) if spec["id"] == args.app]
        if not specs:
            log("%s is not in %s" % (args.app, args.policy))
            return 2
        domain = Domain(specs[0], policy["state_dir"])
        if args.command == "export":
            os.makedirs(policy["state_dir"], mode=0o700, exist_ok=True)
            exported = domain.export()
            print("%d keys exported to %s" % (len(exported), domain.tracked))
        else:
            full = read_domain(domain.domain)
            for key in sorted(full):
                print("%s\t%s" % ("denied" if is_denied(key, domain.deny) else "exported", key))
        return 0

    results = tick_all(load_policy(args.policy), log)
    for app_id, status in sorted(results.items()):
        print("%s\t%s" % (app_id, status))
    return 1 if "error" in results.values() else 0


if __name__ == "__main__":
    sys.exit(main())
