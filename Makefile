# Via http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

arch: dotfiles ## Configure Arch Linux
	bash install/arch.sh

dotfiles: ## Configure dotfiles
	bash install/dotfiles.sh
	bash install/move-dotfiles.sh

git-repos-personal: ## Get personal git repositories
	bash install/git-repos-personal.sh

macos: dotfiles ## Configure macOS (base work & personal device)
	@if [ ! -f '/usr/local/bin/brew' -a ! -f '/opt/homebrew/bin/brew' ]; then \
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"; \
	fi
	brew bundle --file install/Brewfile

macos-personal-device: macos ## Configure a personal macOS device
	brew bundle --file install/Brewfile-personal-device

mainserver: dotfiles ## Configure main server
	bash install/main-server.sh

manjaro: dotfiles ## Configure Manjaro Linux
	bash install/manjaro.sh

moved-dotfiles: ## Move / link dotfiles
	bash install/move-dotfiles.sh

# xubuntu-minimal installation
xubuntu: dotfiles ## Configure xubuntu
	@# didn't test, just moved from old shell script
	@#if grep "ThinkPad X1 Carbon 7th" /sys/devices/virtual/dmi/id/product_family > /dev/null; then
	@#	echo "Identified ThinkPad X1C7"
	@#	sh install/x1c7-config.sh
	@#fi
	bash install/xubuntu.sh
