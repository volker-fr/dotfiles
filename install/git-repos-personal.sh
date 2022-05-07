#!/bin/sh
for repo in \
    volker@c.uhrig.eu.org:/home/volker/git/vimwiki.git \
    volker@c.uhrig.eu.org:/home/volker/git/privat.git \
    volker@c.uhrig.eu.org:/home/volker/git/reddit-scripts.git \
; do
    cd $HOME/repos
    repo_name="$(echo $repo|sed 's,.*/,,'|sed 's/.git//')"
    if [ ! -e "$repo_name" ]; then
        git clone $repo
    else
        echo "REPO $repo already exists"
    fi
done
