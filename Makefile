DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
HOMEBREW_PREFIX := $(shell [[ $$(uname -m) == "arm64" ]] && echo "/opt/homebrew" || echo "/usr/local")
BREW := $(HOMEBREW_PREFIX)/bin/brew
export DOTFILES_DIR
export STOW_DIR = $(DOTFILES_DIR)

.PHONY: all macos sudo brew packages npm-packages vscode-extensions claude-code link unlink defaults work update help

all: macos

# Full macOS setup — run this on a fresh machine
macos: sudo brew packages npm-packages vscode-extensions claude-code link defaults
	@echo ""
	@echo "Setup complete. Restart your terminal or run: exec zsh"

###############################################################################
# sudo: keep alive for the duration of the install
###############################################################################

sudo:
	@sudo -v
	@while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# brew: install Homebrew if missing
###############################################################################

brew:
	@if ! command -v brew &>/dev/null; then \
		echo "Installing Homebrew..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		eval "$$($(BREW) shellenv)"; \
	else \
		echo "Homebrew already installed — skipping."; \
	fi

###############################################################################
# packages: install Brewfile and Caskfile
###############################################################################

packages: brew
	@echo "Installing Brew packages..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile || true
	@echo "Installing Cask apps..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Caskfile || true

###############################################################################
# npm-packages: install global npm packages from npmfile
###############################################################################

npm-packages: packages
	@echo "Installing npm packages..."
	@npm install --location=global $(shell cat $(DOTFILES_DIR)/install/npmfile | tr '\n' ' ')

###############################################################################
# vscode-extensions: install VS Code extensions from vscode-extensions file
###############################################################################

vscode-extensions: packages
	@if ! command -v code &>/dev/null; then \
		echo "VS Code CLI (code) not found — skipping extensions."; \
	else \
		echo "Installing VS Code extensions..."; \
		while IFS= read -r ext || [[ -n "$$ext" ]]; do \
			[[ -z "$$ext" || "$$ext" == \#* ]] && continue; \
			code --install-extension "$$ext" --force; \
		done < $(DOTFILES_DIR)/install/vscode-extensions; \
		echo "VS Code extensions installed."; \
	fi

###############################################################################
# claude-code: install Claude Code plugins and skills
###############################################################################

claude-code: npm-packages
	@if ! command -v claude &>/dev/null; then \
		echo "Claude Code CLI not found — skipping."; \
	else \
		echo "Installing Claude Code plugins..."; \
		claude plugin marketplace add JuliusBrussee/caveman && claude plugin install caveman@caveman; \
		claude plugin marketplace add thedotmack/claude-mem && claude plugin install claude-mem@claude-mem; \
		echo "Claude Code plugins installed."; \
	fi

###############################################################################
# link: symlink shell config files into $HOME using stow
###############################################################################

link: brew
	@if ! command -v stow &>/dev/null; then \
		echo "Installing stow..."; \
		$(BREW) install stow; \
	fi
	@echo "Linking shell config files..."
	@for FILE in $$(ls -A $(DOTFILES_DIR)/shell); do \
		if [[ -f "$(HOME)/$$FILE" && ! -L "$(HOME)/$$FILE" ]]; then \
			echo "  Backing up ~/$$FILE -> ~/$$FILE.bak"; \
			mv "$(HOME)/$$FILE" "$(HOME)/$$FILE.bak"; \
		fi; \
	done
	@stow --target="$(HOME)" --dir="$(DOTFILES_DIR)" shell
	@echo "Shell config files linked."
	@echo "Linking Ghostty config..."
	@if [[ -f "$(HOME)/.config/ghostty/config" && ! -L "$(HOME)/.config/ghostty/config" ]]; then \
		echo "  Backing up ~/.config/ghostty/config -> ~/.config/ghostty/config.bak"; \
		mv "$(HOME)/.config/ghostty/config" "$(HOME)/.config/ghostty/config.bak"; \
	fi
	@stow --target="$(HOME)" --dir="$(DOTFILES_DIR)" ghostty
	@echo "Ghostty config linked."
	@echo "Linking tmux config..."
	@if [[ -f "$(HOME)/.tmux.conf" && ! -L "$(HOME)/.tmux.conf" ]]; then \
		echo "  Backing up ~/.tmux.conf -> ~/.tmux.conf.bak"; \
		mv "$(HOME)/.tmux.conf" "$(HOME)/.tmux.conf.bak"; \
	fi
	@stow --target="$(HOME)" --dir="$(DOTFILES_DIR)" tmux
	@echo "tmux config linked."
	@echo "Linking PowerShell config..."
	@stow --target="$(HOME)" --dir="$(DOTFILES_DIR)" powershell
	@echo "PowerShell config linked."

###############################################################################
# unlink: remove stow symlinks and restore backups
###############################################################################

unlink:
	@stow --delete --target="$(HOME)" --dir="$(DOTFILES_DIR)" shell
	@for FILE in $$(ls -A $(DOTFILES_DIR)/shell); do \
		if [[ -f "$(HOME)/$$FILE.bak" ]]; then \
			echo "  Restoring ~/$$FILE.bak -> ~/$$FILE"; \
			mv "$(HOME)/$$FILE.bak" "$(HOME)/$$FILE"; \
		fi; \
	done
	@echo "Shell config files unlinked."
	@stow --delete --target="$(HOME)" --dir="$(DOTFILES_DIR)" ghostty
	@if [[ -f "$(HOME)/.config/ghostty/config.bak" ]]; then \
		echo "  Restoring ~/.config/ghostty/config.bak -> ~/.config/ghostty/config"; \
		mv "$(HOME)/.config/ghostty/config.bak" "$(HOME)/.config/ghostty/config"; \
	fi
	@echo "Ghostty config unlinked."
	@stow --delete --target="$(HOME)" --dir="$(DOTFILES_DIR)" tmux
	@if [[ -f "$(HOME)/.tmux.conf.bak" ]]; then \
		echo "  Restoring ~/.tmux.conf.bak -> ~/.tmux.conf"; \
		mv "$(HOME)/.tmux.conf.bak" "$(HOME)/.tmux.conf"; \
	fi
	@echo "tmux config unlinked."
	@stow --delete --target="$(HOME)" --dir="$(DOTFILES_DIR)" powershell
	@echo "PowerShell config unlinked."

###############################################################################
# defaults: apply macOS system defaults
###############################################################################

defaults:
	@echo "Applying macOS defaults..."
	@bash $(DOTFILES_DIR)/macos/defaults.sh
	@mkdir -p $(HOME)/Developer
	@echo "macOS defaults applied."

###############################################################################
# work: install work-specific packages and link work shell config
###############################################################################

work: sudo brew
	@echo "Installing work Brew packages..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile.work || true
	@echo "Installing work Cask apps..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Caskfile.work || true
	@echo "Installing tenv managed tools..."
	@tenv tofu install latest && tenv tofu use latest || true
	@tenv tf install latest && tenv tf use latest || true
	@tenv tg install latest && tenv tg use latest || true
	@echo "Installing PowerShell modules..."
	@if command -v pwsh &>/dev/null; then \
		pwsh -NoProfile -File $(DOTFILES_DIR)/install/Install-PwshModules.ps1; \
	else \
		echo "pwsh not found — skipping PowerShell modules."; \
	fi
	@echo "Linking work shell config as ~/.zshrc.local..."
	@if [[ -f "$(HOME)/.zshrc.local" && ! -L "$(HOME)/.zshrc.local" ]]; then \
		echo "  Backing up ~/.zshrc.local -> ~/.zshrc.local.bak"; \
		mv "$(HOME)/.zshrc.local" "$(HOME)/.zshrc.local.bak"; \
	fi
	@ln -sf "$(DOTFILES_DIR)/shell/.zshrc.work" "$(HOME)/.zshrc.local"
	@echo "Cloning private dotfiles..."
	@if [[ ! -d "$(HOME)/.dotfiles-private" ]]; then \
		git clone https://github.com/c-baumgartner/dotfiles-private.git $(HOME)/.dotfiles-private; \
	else \
		git -C $(HOME)/.dotfiles-private pull --rebase; \
	fi
	@$(MAKE) -C $(HOME)/.dotfiles-private clone
	@echo "Work setup complete. Restart your terminal or run: exec zsh"

###############################################################################
# update: pull latest dotfiles and re-run packages + defaults
###############################################################################

update:
	@echo "Updating dotfiles..."
	@git -C $(DOTFILES_DIR) pull --rebase
	@$(MAKE) packages
	@$(MAKE) npm-packages
	@$(MAKE) vscode-extensions
	@$(MAKE) claude-code
	@$(MAKE) defaults
	@echo "Update complete."

###############################################################################
# help
###############################################################################

help:
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "  macos      Full setup on a fresh macOS machine (default)"
	@echo "  packages       Install Homebrew packages and cask apps"
	@echo "  npm-packages       Install global npm packages"
	@echo "  vscode-extensions  Install VS Code extensions"
	@echo "  claude-code        Install Claude Code plugins and skills"
	@echo "  link       Symlink shell + Ghostty configs into ~/"
	@echo "  unlink     Remove shell + Ghostty symlinks, restore backups"
	@echo "  defaults   Apply macOS system defaults"
	@echo "  work       Install work-specific packages and shell config"
	@echo "  update     Pull latest changes and re-run packages + defaults"
	@echo "  help       Show this help"
	@echo ""
