# .dotfiles

These are my dotfiles. Take anything you want, but at your own risk.

## Installation

On a fresh installation of macOS:

```bash
sudo softwareupdate -i -a
xcode-select --install
```

The Xcode Command Line Tools includes `git` and `make` (not available on stock macOS). Now there are two options:

1. Install this repo with `curl` available:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/c-baumgartner/dotfiles/refs/heads/main/remote-install.sh)"
```

This will clone the repo to `~/.dotfiles` and run `make macos` automatically.

2. Alternatively, clone manually and run make:

```bash
git clone https://github.com/c-baumgartner/dotfiles.git ~/.dotfiles
make -C ~/.dotfiles macos
```

## What it does

`make macos` runs the following steps in order:

| Step | What it does |
|---|---|
| `sudo` | Keeps sudo session alive for the duration of the install |
| `brew` | Installs Homebrew if not already present |
| `packages` | Installs CLI tools (`Brewfile`) and GUI apps (`Caskfile`) |
| `npm-packages` | Installs global npm packages (`npmfile`) |
| `link` | Symlinks shell config files into `~/` via GNU stow |
| `defaults` | Applies macOS system defaults |

## Individual targets

```bash
make packages   # Re-install / update Homebrew packages
make link       # Re-symlink shell configs
make unlink     # Remove symlinks, restore any backups
make defaults   # Re-apply macOS defaults
make work       # Install work-specific packages and shell config
make update     # Pull latest dotfiles + re-run packages & defaults
make help       # Show all targets
```

## Work machine setup

On a new company Mac, run the base setup first, then add the work profile:

```bash
make -C ~/.dotfiles macos
make -C ~/.dotfiles work
```

`make work` installs work-specific tools (OpenTofu, Terragrunt, Azure CLI, PowerShell, .NET SDK) and symlinks `shell/.zshrc.work` as `~/.zshrc.local`. Edit `shell/.zshrc.work` to add your work git identity, company-specific aliases, and any additional tools.

## Structure

```
dotfiles/
├── install/
│   ├── Brewfile          # CLI tools via Homebrew
│   ├── Brewfile.work     # Work-specific CLI tools
│   ├── Caskfile          # GUI apps via Homebrew Cask
│   ├── Caskfile.work     # Work-specific GUI apps
│   └── npmfile           # Global npm packages
├── macos/
│   └── defaults.sh   # macOS system defaults
├── shell/
│   ├── .zshrc        # Zsh entry point
│   ├── .zprofile     # Login shell (Homebrew path setup)
│   ├── .exports      # Environment variables
│   ├── .path         # PATH configuration
│   ├── .aliases      # Aliases
│   ├── .functions    # Utility functions
│   └── .zshrc.work   # Work machine shell overrides (symlinked as ~/.zshrc.local)
├── Makefile
└── remote-install.sh
```

## Local overrides

For machine-specific settings (work credentials, local paths, etc.) create `~/.zshrc.local` — it is sourced by `.zshrc` but never tracked in git.
