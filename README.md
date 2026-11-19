<div align="center">

![alvis's dotfiles](logo.svg)

# dotfiles

Awesome dotfiles for MacOS and the PRO, along with powerful configurations for emacs, tmux and zsh.

[![license](https://img.shields.io/github/license/alvis/.dotfiles.svg)](LICENSE)

</div>

This repository contains configurations for CLI commands and X environments, along with powerfully customized Vim, Zsh and Tmux environments for nerds.

![screenshot](screenshot.png)

Welcome, no matter you are looking around how other configure their development environment, or checking me out for my work, welcome.
This repository serves as my way to help me setup and maintain my Mac.
It takes the effort out of installing everything manually.
Everything which is needed to install my preferred setup of macOS is detailed in this readme.
Feel free to explore, learn and copy parts for your own dotfiles. Enjoy!

In a nut shell, the .dotfiles in this repository contain:

1. configurations for zsh, tmux and spacemacs
2. handful of tools such as nvm and miniconda for managing different development environments
3. tons of CLI utilities, from file management to sending email through the terminal
4. many DevOps tools for AWS and K8S

## Important Notes

### Mackup Compatibility Issue with macOS 14 (Workaround Available)

Mackup's preference syncing is currently broken on macOS 14 due to changes in the operating system's security model. Under the new model, macOS no longer follows symlinked application preferences, causing a reset of preferences every time an application starts. For more details, refer to this [GitHub discussion](https://github.com/lra/mackup/issues/1924).

Despite this issue, you can still manually sync preferences and configurations by copying them to and from cloud storage. This approach avoids the symlink problem, effectively allowing preference synchronization across devices.

#### Copying Preferences and Configurations to Cloud Storage

Run the following command to back up your preferences and remove symlinks:

```bash
mackup backup --force && mackup uninstall --force
```

#### Restoring Preferences and Configurations from Cloud Storage

Use this command to restore your preferences and remove symlinks:

```bash
mackup restore --force && mackup uninstall --force
```

This workaround ensures you can continue syncing preferences until a permanent solution is available.

## Installation

**Warning**:
If you would like to give these dotfiles a try, try to play around.
But I strongly encourage you to review the code, and add or remove things you don’t want or need.
Don’t blindly use my settings unless you know what that entails. Use at your own risk!

1. Clone the .dotfiles to home.

```sh
git clone https://github.com/alvis/.dotfiles ~/.dotfiles
```

2. Run the installation script.

```sh
~/.dotfiles/setup.sh
```

3. In tmux, type `prefix + I` to install packages
4. Install fonts: `Hack` & `Input Mono`

## Git sweep

`git sweep` inspects registered Git worktrees and JJ workspaces, reports why each
checkout is pruned or retained. Temporary registrations are forgotten; ordinary
checkouts require retained-work evidence and checkout safety checks. It does not search unregistered folders.

```sh
git sweep --dry-run  # fetch remote history and preview cleanup
git sweep --dry-run --update-snapshot  # permit JJ snapshot verification; no cleanup
git sweep           # refresh evidence, recheck candidates, and clean up
git sweep --dry-run --force-remove-after  # also preview removing kept checkouts idle for 7 days
git sweep --force-remove-after=14  # also remove kept checkouts idle for 14 days
git sweep help
```

The report starts with the number of source trees to **PRUNE** or **RETAIN**,
followed by each tree's registration, location, reason, and evidence. Overlapping
Git/JJ registrations count as one tree. Long locations wrap without truncation.

An actual run displays the report before pruning, then processes each planned
source tree in order. It prints `Pruning <path>...` before the operation and
appends ` done` to the same line after success. Failed or changed candidates receive a
reason and do not count as successful. A completed run ends with
`Operation completed. Pruned <X> source trees.` Preview does not run this phase.

Temporary registrations can qualify for forgetting even when the checkout is
dirty, inaccessible, or broken. The files stay on disk. Primary and invoking
checkouts remain protected. The command rechecks registration identity and
checks for recovery anchors in any bound Git metadata before forgetting a JJ
workspace. Integration evidence is optional under the temporary-registration
policy.

For non-temporary checkouts, **PRUNE** means cleanup evidence and safety checks
pass. **RETAIN** explains the blocker, including uncertain history, dirty files,
broken metadata, or a required snapshot. History is checked first: when a Git
HEAD or JJ `@` lacks retained-history evidence, sweep reports that reason without
reading the checkout's files, even if the checkout is also dirty. The read-only
inspections run in parallel, up to eight at a time and no more than the CPU
count, and the report keeps inventory order. An actual run still repeats every
proof for each candidate, one at a time, immediately before removing it.

For non-temporary checkouts, detached heads, deleted upstreams, and closed PRs
alone do not authorize removal. A JJ commit message does not prevent removal:
described commits undergo the same integration and safety checks as other commits.
Evidence can include ancestry, exact historical-tree equality, a validated merged
PR with the exact head SHA, or an isolated conflict-free merge that reproduces the
default tree. When that merge conflicts or changes content, for example because
the default branch rewrote the same lines after a squash merge, sweep tries each
earlier first-parent default commit after the merge base, oldest first. Merging
the checkout into that commit with the same merge base must reproduce exactly
that commit's tree; each such commit passes the same attribute and merge-driver
checks as the default tip, and the evidence names the commit that matched.
A merged PR is valid when it comes from this repository and its
merge commit is reachable from the default tip; its recorded base branch name is
not compared, so PRs merged before a default-branch rename still count.
Patch-ID equality alone is insufficient.

Sweep builds byte-exact disk trees for Git and JJ checkouts. The proof includes
paths tracked by HEAD or JJ's `@`, paths in the bound Git index, and non-ignored
untracked paths. Git ignore rules govern only the untracked additions. Sweep
hashes raw file bytes and symlink targets, records executable modes, and refuses
gitlinks and unsupported file types. The builder uses a throwaway index and
object store. Git filters, line-ending normalization, and other attribute
conversions do not participate in the comparison.

A plain Git worktree needs a disk tree equal to HEAD. A JJ workspace can qualify
when its disk tree matches default history or a validated merged PR's head and
its `@` passes the integration checks. This covers stale workspaces left behind
when fetching a squash-merged PR moves `@` while leaving the PR's files on disk.
JJ also retains workspaces with `filter`, `text`, `eol`, `ident`, or
`working-tree-encoding` attributes on candidate paths.

Plain Git removal and colocated JJ retirement inspect a copy of the Git index
and any split-index files. The index tree must match HEAD or proven retained
history. Unmerged, skip-worktree, and assume-unchanged entries block removal.
Intent-to-add entries carry no staged bytes, and their paths are still included
in the byte-exact disk proof.

Sweep checks every nonzero commit ID recorded in both columns of the bound Git
admin directory's `logs/HEAD` as well as the IDs in `FETCH_HEAD`. Each must
pass the same retained-history proof as HEAD or be reachable from a durable ref.
An unreadable object, a non-commit object, or a commit with neither proof blocks
retirement. A colocated workspace also needs a verified Git registration and
retained Git HEAD. Plain Git worktree removal and colocated JJ retirement apply
the same admin-directory allowlist. In-progress merge, rebase, cherry-pick, or
bisect metadata, `config.worktree`, `locked`, per-worktree refs, and reflogs
other than `logs/HEAD` block retirement. An `ORIG_HEAD` is allowed when it
names a commit reachable from the verified default tip. Leftovers that hold
nothing unique are allowed too: an empty `MERGE_RR`, an `AUTO_MERGE` naming a
tree while no merge, cherry-pick, revert, bisect, rebase, or sequencer operation
is in progress, and any other top-level file whose whole content is one full
commit ID that a durable ref (defined below) contains, such as an `ORIG_HEAD`
on a local branch, a tool's `CLAUDE_BASE`, or a stale `REBASE_HEAD`.
`MERGE_HEAD`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, `BISECT_*`, and a
`REBASE_HEAD` beside `rebase-merge/` or `rebase-apply/` always block. A `COMMIT_EDITMSG` is
allowed only when, after discarding everything from a verbose commit's scissors
line onward and stripping comments, it is empty or equals the full message of
HEAD or of a commit recorded in `logs/HEAD`; any other draft blocks retirement. An
empty `refs/` directory tree may contain directories only. Any file, symlink,
or other non-directory entry under it blocks retirement.

Temporary registration removal uses a variant of that allowlist. Commits named
by `logs/HEAD`, `FETCH_HEAD`, `ORIG_HEAD`, or per-worktree refs under
`refs/worktree`, `refs/bisect`, or `refs/rewritten` are pinned under
`refs/sweep/recovery/git/<admin>/anchor/<oid>` when no durable ref already
contains them, and are then allowed. Durable refs are local branches, tags,
remote-tracking branches, `refs/jj`, and `refs/sweep/recovery`; a commit kept
only by a remote-tracking branch is lost if that branch is later pruned. Pinning starts only after every other
admin entry passes. In-progress operation state, `locked`, `config.worktree`,
unknown entries, missing or non-commit anchor objects, and per-worktree ref
files that Git does not list (malformed names such as `a..b` or `x.lock`)
block removal. The HEAD and index are saved under `refs/sweep/recovery` before
the registration goes; when the HEAD commit is missing from the object store,
the index is saved as a parentless recovery commit whose ref name and message
carry the missing ID. These read-only checks run while planning in every mode,
so a deterministic blocker is reported as **RETAIN** in both preview and the
real-run report; only a concurrent change can still fail during execution, and
then the registration is kept.

Unused custom merge-driver
configuration, such as `merge.ours.driver=true`, does not block the isolated merge
proof. A selected custom driver, a nonstandard default merge driver, versioned or
unverifiable attributes, missing objects, or incomplete PR queries disable affected
proofs; the report identifies the blocker. Simulated merges run with isolated
configuration and built-in merging, without executing custom drivers.
Merge-conflict evidence includes the number of conflicted paths and a short
sample. Tool failures show Git's exit status and error text; a clean merge that
would change the default tree is reported separately.
Tracked changes and non-ignored untracked files prevent removal. Ordinary
files matched by ignore rules, including test caches and generated assets, do not
block cleanup and are removed with an otherwise eligible checkout. Nested
repositories and submodules remain protected even when ignored; folders named
`node_modules` are not searched for them.
Content-blocker evidence names a sampled path so you can inspect retained work.
When a checkout lacks its root `.gitignore`, every mode, including dry-run,
temporarily uses the primary checkout's file for verification and then removes
the owned temporary copy. Existing or concurrently replaced ignore files are
preserved.

Every run fetches remote history before checking cleanup evidence, including
dry-run. Fetching updates remote-tracking refs and repository objects. Plain
dry-run does not snapshot JJ working copies, repair metadata, or remove checkouts.
Add `--update-snapshot` to allow JJ snapshot
verification during preview. **This may update JJ commits and operations and
alter working-copy file structure.** The command warns before proceeding; it
still preserves registrations and performs no cleanup, rebase, or stale
workspace repair. The flag requires `--dry-run`.

After fetching, preview checks remote freshness again. Failed remote queries, missing
remote refs, and differing remote/cached SHAs receive distinct messages. When
both commit objects are already local, the mismatch message compares their
committer dates; otherwise it reports that dates are unavailable locally.
Timestamps do not prove ancestry. Preview may report fewer eligible checkouts than a real run.
A real run rechecks identity and cleanliness before removal. For a JJ workspace,
it records the checkout, its sibling quarantine path, and any Git admin backup
in a recovery note before moving them. A successful prune prints none of these
paths; they are printed when the prune fails, is interrupted, or leaves the
quarantine in place. If sweep is killed without a chance to report, look for
`.<name>.git-sweep-quarantine.*` beside the checkout and `.git-sweep-admin.*`
in the Git common directory. Sweep proves
the quarantined disk tree against retained history or against the verified
`@` tree for a snapshot-based decision. Before forgetting the workspace,
sweep rechecks the JJ target and verifies that the quarantine root's `.git`
is still absent, either because the workspace is native or because its bound
Git metadata was retired. It checks `.git` again before deleting the quarantine.
If verification fails or sweep receives HUP, INT, or TERM before
forgetting starts, it attempts to restore the checkout and its Git metadata.
If restoration fails or an interruption occurs after forgetting starts, sweep
reports the recovery locations. A residual window remains between the final
proof and deletion: a process can still write through a descriptor it opened
before quarantine, and a process whose working directory is inside the
workspace can create files there. Plain Git worktree removal has no
quarantine; after the final byte-exact proof, only `git worktree remove`'s own
status check, which applies text and line-ending conversion, remains. A broken JJ
workspace does not suppress independently verified workspace retirement; incomplete
shared-reference evidence still blocks dependent history abandonment. Missing
non-temporary registrations are retained unless their history has a verified
recovery anchor. Preview never forgets registrations or creates recovery refs.

Integration evidence uses `origin`'s default branch. Sweep queries merged and
closed PRs concurrently, starting with a limit of 1,000 each. A query whose
result reaches its limit repeats with twice the limit; at the 64,000-PR ceiling,
completeness stays unverified. Closed-unmerged PRs remain report-only. Preview is
selected with `--dry-run`; there are no sweep-specific environment settings.

### Removing idle checkouts

`--force-remove-after[=N]` also removes checkouts that the rules above retain,
once they have been idle for at least N days; N defaults to 7. It applies to
non-primary Git worktrees and to colocated and native JJ workspaces. Checkouts the
normal rules prune are pruned as before. N must be a non-negative whole number
attached with `=`; a negative or non-numeric value, or N as a separate argument,
is a usage error. Add `--dry-run` to preview. Without the flag, behavior and
output are unchanged.

Activity is checked cheapest first against a cutoff of N days before now. The
first signal newer than the cutoff keeps the checkout, and the report names that
signal and its age; no later signal is read.

1. The committer time of the Git HEAD or JJ `@` commit.
2. The last HEAD move: the newest timestamp recorded inside the worktree's
   `logs/HEAD`, not the file's own time. For a JJ workspace, this is the time of
   `.jj/working_copy/checkout`, which JJ rewrites whenever an operation updates
   that working copy. A colocated workspace also checks its Git `logs/HEAD`.
3. Changed files: staged, modified, deleted, and untracked non-ignored paths,
   examined one at a time. The scan stops at the first file newer than the
   cutoff, so later paths are never read. Without a snapshot, JJ records no
   per-file state that sweep reads, so a JJ workspace has every file of `@` and
   its untracked non-ignored files scanned.

The index file's time, directory times, and ignored files never count. A
deletion or rename leaves no newer file behind, so a checkout whose only recent
work is deleting or renaming files reads as idle. A path
that cannot be examined keeps the checkout as unverifiable. With `=0`, sweep skips
the activity check.

Some checkouts are kept whatever their age:

- the primary checkout and the checkout sweep runs from;
- locked Git worktrees;
- checkouts with an operation in progress: `MERGE_HEAD`, `CHERRY_PICK_HEAD`,
  `REVERT_HEAD`, `BISECT_LOG`, `rebase-merge/`, `rebase-apply/`, or `sequencer/`
  in the worktree's Git admin directory, or a JJ `@` with unresolved conflicts;
- checkouts holding a nested repository, found by the same walk that
  normal runs use; to save time, the walk runs only for an idle checkout;
- checkouts whose identity, registration, history, or files cannot be verified,
  including quoted or delimiter-bearing paths and missing registrations.

Temporary registrations keep the temporary-registration policy.

A force removal saves nothing: sweep creates no archive refs. A Git worktree is
removed with `git worktree remove --force`. A JJ workspace goes through the
existing quarantine, `jj workspace forget`, and interruption rollback, without the
integration and cleanliness proofs. Uncommitted and unsnapshotted changes, a
detached HEAD that no branch contains, and the worktree's Git admin state, such
as its reflog, are discarded. Branches and bookmarks are not removed with the
checkout, but once no checkout holds one, the existing branch and stack cleanup
rules apply in the same run, so a branch already merged into the default branch
is deleted as usual. The report shows the idle age,
the newest activity, what is discarded, and the normal rule that retained the
checkout. A real run checks the guards and activity again just before each
removal and keeps a checkout that has become active or guarded. Force-removed
checkouts count as pruned source trees.

## About

In my opinion, using your computer should be a very personal experience.
Your colors, aliases, key-bindings, etc should be meticulously crafted to fit your unique self.

In terms of computer setup I prefer something minimal and clean.
I choose to interact with my operating system via the so-called terminal or command line or console, over a graphical interface whenever I can.
As I work on the terminal at least 50% of my time, with the rest on a web browser and email client,
I have quite a number of meticulously crafted and opinionated .dotfiles designed for fitting my personal use, and I don't expect anyone would use it.

But having said that, I believe sharing it openly may inspire someone like you to explore and make knowledge continue to accumulate.
The open community is where I benefited from and where I got most knowledge.
As such I am very happy to share it with you if you find value from it.
Remember, get inspired from it and make your own.

### Thanks for Inspiration

As far as dotsfiles are concerned, I particularly thanks [Sourabh Bajaj](https://github.com/sb2nov) for his invaluable [Mac OS X Setup Guide](http://sourabhbajaj.com/mac-setup).
Also the [Github does dotfiles](https://dotfiles.github.io) project is what motivate me to share my configurations behind the scene.

In general, I'd like to thank every single one who contributed to the open community.
Your work means the world! :earth_africa: :heart:

### License

Copyright © 2017, [Alvis Tang](https://github.com/alvis). Released under the [MIT License](LICENSE).
