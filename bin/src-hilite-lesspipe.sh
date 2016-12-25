#! /bin/sh -e

if [ ! -d "$HOME/repos/dotfiles/source-highlight-solarized" ]; then
    cd "$HOME/repos/dotfiles"
    git clone https://github.com/jrunning/source-highlight-solarized.git
fi
STYLE_FILE="$HOME/repos/dotfiles/source-highlight-solarized/esc-solarized.style"

for source in "$@"; do
    case $source in
    *ChangeLog|*changelog)
        source-highlight --failsafe -f esc --lang-def=changelog.lang --style-file=$STYLE_FILE -i "$source" ;;
    *Makefile|*makefile) 
        source-highlight --failsafe -f esc --lang-def=makefile.lang --style-file=$STYLE_FILE -i "$source" ;;
    *.tar|*.tgz|*.gz|*.bz2|*.xz)
        lesspipe "$source" ;;
        *) source-highlight --failsafe --infer-lang -f esc --style-file=$STYLE_FILE -i "$source" ;;
    esac
done
