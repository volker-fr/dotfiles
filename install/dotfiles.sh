installDotfiles(){
    repoDir="$(cd "$(dirname "$0")" && pwd -P)"

    # regular dotfiles to link
    EXTRA_FILES=""
    if [ "$(uname -s)" = "Linux" ]; then
        EXTRA_FILES="Xresources i3"
    fi

    # old files: bashrc bash
    for file in bc.rc tmux.conf vimrc inputrc zshrc $EXTRA_FILES; do
        source="$repoDir/$file"
        target="$HOME/.$file"
        # File existing but not linked?
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "TODO: $target exists but is not a link. Please delete it"
            exit 1
        # link it
        elif [ ! -e "$target" ]; then
            echo "* linking $file to $target"
            ln -s "$source" "$target"
        # already linked
        #else
        #    echo "$file already linked to $target"
        fi
    done

    [ ! -f "$HOME/.dircolors" ] && curl -s -o "$HOME/.dircolors" \
        https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark

    if [ "$(uname -s)" = "Linux" ]; then
        # only run these settings if X11 is installed/running
        if pidof X > /dev/null || pidof Xorg > /dev/null; then
            # To open URL's in a docker container
            #   No more docker for some application for now
            #mkdir -p "$HOME/.local/share/applications"
            #ln -sf "$repoDir/x11/browser.desktop" \
            #    "$HOME/.local/share/applications/"
            #if which update-desktop-database >/dev/null; then
            #    update-desktop-database "$HOME/.local/share/applications"
            #fi
            #if which gvfs-mime >/dev/null; then
            #    gvfs-mime --set "x-scheme-handler/http" "browser.desktop"
            #    gvfs-mime --set "x-scheme-handler/https" "browser.desktop"
            #fi

            # update default xdg-dirs
            if which xdg-user-dirs-update > /dev/null 2>&1; then
                xdg-user-dirs-update --set DESKTOP "$HOME"
                xdg-user-dirs-update --set TEMPLATES "$HOME"
                xdg-user-dirs-update --set DOCUMENTS "$HOME"
                xdg-user-dirs-update --set MUSIC "$HOME"
                xdg-user-dirs-update --set PICTURES "$HOME"
                xdg-user-dirs-update --set VIDEOS "$HOME"
            fi
        fi
    fi

    # link ssh to localdata directory
    dotSSH="$HOME/localdata/dotfiles/ssh"
    mkdir -p "$dotSSH" && chmod 700 "$dotSSH"
    if [ -e "$HOME/.ssh" ] && [ ! -L "$HOME/.ssh" ]; then
        echo "$HOME/.ssh exists but isn't a link"
        echo "consider moving it to $dotSSH"
        exit 1
    fi
    test -e "$HOME/.ssh" || ln -sfn "$dotSSH" "$HOME/.ssh"
    sshConfig="$dotSSH/config"
    test -f "$sshConfig" || cp "$repoDir/ssh/config" "$sshConfig"
    mkdir -p "$HOME/.ssh/sessions" && chmod 700 "$HOME/.ssh/sessions"

    # vim
    mkdir -p "$HOME/.vim/cache"
    mkdir -p "$HOME/.vim/view"
    mkdir -p "$HOME/.vim/autoload"
    # overwriting is ok in case the code updates
    curl -s -o "$HOME/.vim/autoload/plug.vim" \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    # Neovim setup/linking
    if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        echo "$HOME/.config/nvim exists but isn't a link"
        echo "Please remove it"
        exit 1
    fi
    test -e "$HOME/.config/nvim" || ln -sfn "$HOME/.vim" "$HOME/.config/nvim"
    test -e "$HOME/.vim/init.vim" || ln -sfn "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"

    # local bashrc
    #touch "$HOME/localdata/dotfiles/bashrc.local" \
    #    && ln -sf "$HOME/localdata/dotfiles/bashrc.local" "$HOME/.bashrc.local"

    # zsh
    if [ ! -e $HOME/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi
    if [ ! -e $HOME/localdata/dotfiles/zshrc.local ]; then
        touch $HOME/localdata/dotfiles/zshrc.local
    fi
    touch "$HOME/localdata/dotfiles/zshrc.local" \
        && ln -sf "$HOME/localdata/dotfiles/zshrc.local" "$HOME/.zshrc.local"
}
