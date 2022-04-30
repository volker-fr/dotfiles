macosPackages() {
    if [ ! -f '/usr/local/bin/brew' -a ! -f '/opt/homebrew/bin/brew' ]; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    fi

    brew install \
        wget \
        tmux \
        coreutils \
        findutils \
        source-highlight \
        watch \
        imagemagick \
        jq \
        neovim \
        mpv \

    # tmux tabcompletion etc will fail without it
    #brew install bash-completion
    # vim code checker
    brew install jsonlint shellcheck flake8
    # tmux workaround for open etc
    #brew install reattach-to-user-namespace
    # for vim-youcompleteme
    #brew install cmake go

    brew install --cask \
        iterm2 \
        firefox \
        google-chrome \
        amethyst \
        vlc
}
