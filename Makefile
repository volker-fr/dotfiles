.PHONY: all dotfiles localdata-dotfiles
all: git-dotfiles localdata-dotfiles

git-dotfiles:
	@# individual single dotfiles/folders
	ln -sfn $(CURDIR)/i3 $(HOME)/.i3
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
	test -L $(HOME)/.thunderbird && rm -rf $(HOME)/.thunderbird
	test -d $(HOME)/localdata/dotfiles/dot_thunderbird \
		&& ln -sfn $(HOME)/localdata/dotfiles/dot_thunderbird \
			$(HOME)/.thunderbird
	test -f $(HOME)/localdata/dotfiles/dot_bashrc.local \
		&& ln -sf $(HOME)/localdata/dotfiles/dot_bashrc.local $(HOME)/.bashrc.local
