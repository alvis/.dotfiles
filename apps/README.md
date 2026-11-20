# Application registry

Each `<id>.toml` file says how one application's personal settings are found
and synchronized through your private `.configs` history. `dotfiles config
list` reads these files; `dotfiles config add <id>` enrolls one.

```toml
schema = 1

[app]
id = "bartender"                 # file name without .toml
name = "Bartender"
platforms = ["macos"]            # macos, linux
install = "brew-cask:bartender"  # the blueprint package that installs it

[compat]
verified = true                  # false: `config add` requires --unverified
versions = "5-7"                 # application versions the paths were checked with
checked = "2026-11-20, Bartender 7.2.0, macOS 27.2"

[sync]
strategy = "auto"                # auto | manual | excluded
default = true                   # selected by `config init` unless --apps says otherwise
method = "defaults"              # defaults: sanitized plist export; file: track paths in place
reload = "restart-if-running"    # none | restart-if-running | next-launch
domain = "com.surteesstudios.Bartender"   # method = "defaults"
bundle_id = "com.surteesstudios.Bartender"
deny_keys = ["wdsAuthToken"]     # method = "defaults": top-level keys never exported (globs)
paths = ["~/.gitconfig"]         # method = "file": files tracked in place
include = []                     # method = "file", directory paths: files to keep
actions = []                     # named built-in actions, see bin/dotfiles `app_action`

[unsafe]
paths = ["~/.aws/credentials"]   # never tracked, even if a path above contains them
notes = "Why the policy is what it is, and what stays manual."
```

## Strategies

| Strategy   | What happens                                                                                     |
| ---------- | ------------------------------------------------------------------------------------------------ |
| `auto`     | Saved, pushed, fetched, and applied on every machine automatically.                              |
| `manual`   | Not tracked. `notes` explains the application's own export/import route.                         |
| `excluded` | Never tracked: credentials, live databases, or system-managed state.                             |

## Methods

`file` tracks real files where the application reads them (`mise dot track`).

`defaults` is for macOS preference domains. Copying a live plist under a
running app is unsafe because `cfprefsd` caches preferences and the app writes
its cached copy back. Many plists also hold tokens, cached locations, and
machine state. The `dotfiles-watch` user service therefore exports a
**sanitized** XML copy to `~/.config/dotfiles/prefs/<domain>.plist`, with
`deny_keys` and the global deny list removed, and mise tracks that copy. Incoming
copies are merged key by key (base, incoming, live) and applied with
`defaults import` while the app is stopped, as `reload` says.

The global deny list (always applied) removes keys matching: `NSWindowFrame*`,
`NSNavPanel*`, `NSSplitView*`, `NSTableView*`, `NSToolbar*`, `NSOSPLast*`,
`NSStatusItem Visible*`, `SU*` (Sparkle updater state), `*SecurityScopedBookmark*`,
`*[Tt]oken*`, `*[Ss]ecret*`, `*[Pp]assword*`, `*[Ll]icen[cs]e*`, `*Serial*`,
`*APIKey*`, `*ApiKey*`, `*[Ll]atitude*`, `*[Ll]ongitude*`, `*LastCheck*`,
`*LastLaunch*`, `NoSync*`.
