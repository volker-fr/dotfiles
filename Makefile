.PHONY: all dotfiles localdata-dotfiles x11 xdg-dirs
all: git-dotfiles localdata-dotfiles others x11 xdg-dirs

UNAME_S := $(shell uname -s)

git-dotfiles:
	@# individual single dotfiles or folders
	ln -sfn $(CURDIR)/i3 $(HOME)/.i3
	ln -sf $(CURDIR)/tmux.conf $(HOME)/.tmux.conf
	ln -sf $(CURDIR)/Xresources $(HOME)/.Xresources
	@# bash
	ln -sfn $(CURDIR)/bash $(HOME)/.bash
	ln -sf $(CURDIR)/bashrc $(HOME)/.bashrc
	@# ssh
	mkdir -p $(HOME)/localdata/dotfiles/dot_ssh \
		&& chmod 700 $(HOME)/localdata/dotfiles/dot_ssh
	ln -sfn $(HOME)/localdata/dotfiles/dot_ssh $(HOME)/.ssh
	test -f $(HOME)/localdata/dotfiles/dot_ssh/config \
		|| cp $(CURDIR)/ssh/config \
			$(HOME)/localdata/dotfiles/dot_ssh/config
	mkdir -p $(HOME)/.ssh/sessions \
		&& chmod 700 $(HOME)/.ssh/sessions
	@# vim
	ln -sf $(CURDIR)/vimrc $(HOME)/.vimrc
	mkdir -p $(HOME)/.vim/autoload
	wget -q -O $(HOME)/.vim/autoload/plug.vim \
		https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

localdata-dotfiles:
	test -L $(HOME)/.thunderbird && rm -rf $(HOME)/.thunderbird || true
	test -d $(HOME)/localdata/dotfiles/dot_thunderbird \
		&& ln -sfn $(HOME)/localdata/dotfiles/dot_thunderbird \
			$(HOME)/.thunderbird \
		|| true
	test -f $(HOME)/localdata/dotfiles/dot_bashrc.local \
		&& ln -sf $(HOME)/localdata/dotfiles/dot_bashrc.local $(HOME)/.bashrc.local \
		|| true

others:
	wget -q -O $(HOME)/.dircolors https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark

x11:
ifeq ($(UNAME_S),Linux)
		mkdir -p $(HOME)/.local/share/applications
		ln -sf $(CURDIR)/x11/browser.desktop $(HOME)/.local/share/applications/
		update-desktop-database $(HOME)/.local/share/applications
		gvfs-mime --set "x-scheme-handler/http" "browser.desktop"
		gvfs-mime --set "x-scheme-handler/httpm" "browser.desktop"
endif

xdg-dirs:
ifeq ($(UNAME_S),Linux)
		xdg-user-dirs-update --set DESKTOP $(HOME)
		xdg-user-dirs-update --set TEMPLATES $(HOME)
		xdg-user-dirs-update --set DOCUMENTS $(HOME)
		xdg-user-dirs-update --set MUSIC $(HOME)
		xdg-user-dirs-update --set PICTURES $(HOME)
		xdg-user-dirs-update --set VIDEOS $(HOME)
endif
