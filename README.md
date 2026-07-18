# Dupacode

**A personal fork of [Supacode](https://github.com/supabitapp/supacode) — a native macOS command
center for running coding agents in parallel — with opinionated UI/UX changes for maximum
terminal space.**

Run several coding agents side by side from one window: each task gets its own git worktree and
its own real terminal. Sessions persist in the background, so quitting the app or dropping an SSH
connection loses nothing. All credit for the app itself goes to
[Supabit](https://supacode.sh); this fork only reshapes the chrome.

## How Dupacode differs from Supacode

- **Terminal tabs live in the titlebar.** The tab bar renders in the window's top strip (via an
  AppKit titlebar accessory) next to the traffic lights, and the worktree title block is gone —
  the terminal starts directly under the tabs and gains two full rows of height.
- **Minimal chrome.** No toolbar buttons (open-in-editor, run script, inspector toggles), no
  tab-bar new-tab/split buttons, no onboarding/announcement cards. Everything stays reachable
  through the menu bar, keyboard shortcuts, and the command palette.
- **Always-visible sidebar.** The sidebar cannot be collapsed; the toggle button, menu item, and
  shortcut are removed. The add-repository menu sits in the titlebar strip.
- **Your Ghostty config owns appearance.** Theme sync injects only the light/dark theme;
  `background-opacity`, `background-blur`, fonts, and everything else come from your own
  [Ghostty](https://ghostty.org) config (`~/.config/ghostty/config`) with normal reload
  semantics. Unset means opaque.
- **The CLI is `dupacode`.** Same commands as upstream's `supacode` CLI, different name.
- **Fully isolated from a stock Supacode install.** Different bundle id (`app.supabit.dupacode`),
  state root (`~/.dupacode`), IPC sockets (`/tmp/dupacode-<uid>`), zmx session namespace
  (`dupa-*` in `dmx` socket dirs), and URL scheme (`dupacode://`). Both apps can run side by side
  without touching each other's sessions or settings.
- **No auto-updates.** Sparkle is disabled so the fork never updates itself into stock Supacode.
  Updates come from merging upstream: a weekly GitHub Action posts an `upstream-digest` issue
  summarizing unmerged upstream commits and flagging merge-conflict risks against fork-modified
  files.

Everything else — worktree-first workflow, zmx-backed session persistence, remote SSH
repositories, agent presence badges, pull request tracking, custom scripts, the command palette —
is inherited from upstream; see the [Supacode README](https://github.com/supabitapp/supacode#readme)
for the full feature tour.

## Requirements

- macOS 26.0+
- [mise](https://mise.jdx.dev/) for the pinned toolchain. Add `~/.local/bin` to your `PATH`.
- git submodules: `git submodule update --init --recursive`
- **Xcode 26.3** if you are on macOS 26.4+ (see [below](#building-on-macos-264-tahoe)).

## Quick start

```bash
git clone --recursive https://github.com/EddiePikulya/dupacode.git
cd dupacode
mise install
make doctor    # check every build prerequisite and print fixes for anything missing
make run-app   # build and launch the Debug app
```

`make doctor` verifies mise, submodules, a Zig-linkable Xcode, the Metal Toolchain, and the
pinned tools, and prints the exact command to fix anything that is missing.

To install the built app:

```bash
make build-app
ditto .build/DerivedData/Build/Products/Debug/Dupacode.app /Applications/Dupacode.app
```

The `dupacode` CLI is bundled inside the app and on `PATH` in every Dupacode terminal. To use it
from other terminals: `ln -s /Applications/Dupacode.app/Contents/Resources/bin/dupacode /usr/local/bin/dupacode`.

## Building on macOS 26.4+ (Tahoe)

GhosttyKit is built with a pinned Zig (`0.15.2`, required exactly by ghostty) whose linker cannot
link the macOS 26.4+ SDK ([ziglang/zig#31658](https://github.com/ziglang/zig/issues/31658)).
Install [Xcode 26.3](https://developer.apple.com/download/all/?q=Xcode%2026.3) side by side (no
global switch needed — the build auto-detects it), then:

```bash
sudo DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer xcodebuild -license accept
sudo DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer xcodebuild -runFirstLaunch
sudo DEVELOPER_DIR=/Applications/Xcode_26.3.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain
```

**If the Metal Toolchain download fails** with `Failed fetching catalog for assetType
(com.apple.MobileAsset.MetalToolchain)`, Apple's asset server no longer serves the toolchain for
Xcode 26.3's build. Workaround: download it through your newer Xcode
(`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent
MetalToolchain`), then replace Xcode 26.3's `metal` stub with a wrapper that delegates to it —
back up `Toolchains/XcodeDefault.xctoolchain/usr/bin/metal`, and install shell shims for `metal`
and `metallib` that `exec /usr/bin/env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
/usr/bin/xcrun metal[lib] "$@"`. Shader output is toolchain-version independent; linking still
uses the 26.2 SDK.

## Development

```bash
make check   # swift-format + swiftlint
make test    # run the tests
make format  # swift-format only
```

Fork-specific rule: keep the diff against upstream small and concentrated. Every customization is
a focused commit on the `dupacode` branch so `git merge upstream/main` stays painless. When a new
fork change touches a new file, add it to the watch list in
`.github/scripts/upstream-digest.sh`.

## Updates: weekly upstream review

Dupacode tracks upstream Supacode deliberately, not automatically. Every week the
`Upstream digest` GitHub Action (Mondays, or manual dispatch) opens an issue summarizing every
upstream commit not yet merged here — new features, fixes, fresh release tags — and flags the
ones that touch fork-modified files (merge-conflict risk). The changes that make sense for
Dupacode get merged and shipped; the ones that fight its design (e.g. toolbar redesigns) get
skipped or adapted. Quiet upstream weeks produce no issue.

Applying an update:

```bash
git fetch upstream            # upstream = https://github.com/supabitapp/supacode
git merge upstream/main       # usually clean; conflicts only in fork-modified files
make build-app
```

## Contributing

Anyone is welcome to contribute — issues, ideas, and pull requests alike. This is a personal
fork with strong UI opinions, so the bar for a change is "does it keep the terminal maximal and
the chrome minimal", but if that sounds like your kind of terminal, come on in. For changes to
the underlying app rather than the fork's chrome, consider contributing them
[upstream](https://github.com/supabitapp/supacode) so everyone benefits — this fork happily
inherits them through the weekly digest.

## Technical stack

- [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
- [libghostty](https://github.com/ghostty-org/ghostty)
- [zmx](https://zmx.sh) for session persistence

## License

Inherited from upstream Supacode: [FSL-1.1-ALv2](LICENSE) — free to use, modify, and share for
any non-competing purpose. This fork is a personal-use modification, exactly what the license
permits.
