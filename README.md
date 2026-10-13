**FLEXGET UPDATE:** I have moved my flexget configuration to [jawilson/flexget-config](https://github.com/jawilson/flexget-config) since it's not necessary on all of my devices. Sorry for any inconvienience that may cause you.

# Jeff Wilson Dot Files

These are config files to set up a system the way I like it.

## Installation

Machine setup is declared in `mise*.toml` and applied by `mise bootstrap`. `install.sh` only installs what mise cannot install for itself (Homebrew, Scoop, mise), records the profile, and runs `mise bootstrap`.

### New Mac

1. Wait for JumpCloud to install its apps (work).
2. Sign in to 1Password and turn on its SSH agent (git SSH access and commit signing use it). On personal Macs, install 1Password manually first; it is not installed by this setup.
3. Sign in to the App Store.
4. Run:

       xcode-select --install
       git clone https://github.com/jawilson/dotfiles.git ~/src/dotfiles
       ~/src/dotfiles/install.sh --profile work

### Debian/Ubuntu

Clone the repo, then run `./install.sh --profile <profile>`.

### Windows

1. In an elevated PowerShell, download and run the prerequisite script:

       Invoke-WebRequest https://raw.githubusercontent.com/jawilson/dotfiles/main/tools/install/bootstrap-windows.ps1 -OutFile "$env:TEMP\bootstrap-windows.ps1"
       powershell -NoProfile -ExecutionPolicy Bypass -File "$env:TEMP\bootstrap-windows.ps1"

2. Clone the repo.
3. In the MSYS2 shell, run `./install.sh --profile <profile>`.

### Profiles

`work` or `personal`. The choice is remembered in `.miserc.local.toml`.

### Day to day

Run these from the repository (mise reads the platform and profile files only from the repository directory):

- `mise bootstrap` reapplies everything.
- `mise bootstrap status --missing` reports drift.
- `mise bootstrap packages upgrade` replaces `brew upgrade` for casks that mise installed.
- `mise dot apply` after editing links.
- zsh-autosuggestions, zsh-better-npm-completion and powerlevel10k are cloned by `[bootstrap.repos]` in `mise.toml`, pinned to a tag or commit. To upgrade one, change its `ref` and run `mise bootstrap repos apply`.
- If one package fails on a new machine, `mise bootstrap --skip packages` attempts the rest; steps that need the missing package may still fail.

### Manual follow-ups on a new Mac

- Add the U.S. and Dvorak input sources (System Settings > Keyboard > Text Input > Input Sources). To use Wilson Dvorak, install it by hand from `~/src/wilson-dvorak`, enable it there, then run `mise bootstrap` again as usual and reload Hammerspoon (menu bar icon > Reload Config); until it is enabled, Hammerspoon uses standard Dvorak.
- Log out and back in. The modifier remap and Dark Mode need a new login.
- Grant Accessibility and Screen Recording to Karabiner, Hammerspoon, Rectangle, DockDoor, MonitorControl, and FineTune.
- Sign in to VS Code Settings Sync and Docker (and Tailscale on the work profile).
- Run `gh auth login`, then `mise bootstrap` again (installs `gh-stack`).
- Set the default handlers: Chrome as the browser, VS Code for plain text, Ghostty for executables.
