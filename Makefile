DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
HOMEBREW_PREFIX := $(shell [[ $$(uname -m) == "arm64" ]] && echo "/opt/homebrew" || echo "/usr/local")
BREW := $(HOMEBREW_PREFIX)/bin/brew
export DOTFILES_DIR
export STOW_DIR = $(DOTFILES_DIR)

.PHONY: all macos sudo brew packages npm-packages link defaults work update help

all: macos

# Full macOS setup — run this on a fresh machine
macos: sudo brew packages npm-packages link defaults
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
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile --no-lock || true
	@echo "Installing Cask apps..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Caskfile --no-lock || true

###############################################################################
# npm-packages: install global npm packages from npmfile
###############################################################################

npm-packages: packages
	@echo "Installing npm packages..."
	@npm install --location=global $(shell cat $(DOTFILES_DIR)/install/npmfile | tr '\n' ' ')

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

###############################################################################
# defaults: apply macOS system defaults
###############################################################################

defaults:
	@echo "Applying macOS defaults..."
	@bash $(DOTFILES_DIR)/macos/defaults.sh
	@echo "macOS defaults applied."

###############################################################################
# work: install work-specific packages and link work shell config
###############################################################################

work: sudo brew
	@echo "Installing work Brew packages..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Brewfile.work --no-lock || true
	@echo "Installing work Cask apps..."
	@$(BREW) bundle --file=$(DOTFILES_DIR)/install/Caskfile.work --no-lock || true
	@echo "Linking work shell config as ~/.zshrc.local..."
	@if [[ -f "$(HOME)/.zshrc.local" && ! -L "$(HOME)/.zshrc.local" ]]; then \
		echo "  Backing up ~/.zshrc.local -> ~/.zshrc.local.bak"; \
		mv "$(HOME)/.zshrc.local" "$(HOME)/.zshrc.local.bak"; \
	fi
	@ln -sf "$(DOTFILES_DIR)/shell/.zshrc.work" "$(HOME)/.zshrc.local"
	@echo "Work setup complete. Restart your terminal or run: exec zsh"

###############################################################################
# update: pull latest dotfiles and re-run packages + defaults
###############################################################################

update:
	@echo "Updating dotfiles..."
	@git -C $(DOTFILES_DIR) pull --rebase
	@$(MAKE) packages
	@$(MAKE) npm-packages
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
	@echo "  npm-packages   Install global npm packages"
	@echo "  link       Symlink shell config files into ~/"
	@echo "  unlink     Remove shell config symlinks, restore backups"
	@echo "  defaults   Apply macOS system defaults"
	@echo "  work       Install work-specific packages and shell config"
	@echo "  update     Pull latest changes and re-run packages + defaults"
	@echo "  help       Show this help"
	@echo ""
