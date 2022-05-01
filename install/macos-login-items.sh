#!/bin/sh
set -e
set -u
set -o pipefail

macosLoginItems(){
    # to automatically add login items
    brew install OJFord/formulae/loginitems

    loginitems -a Flux -s false
    loginitems -a RescueTime -s false
    loginitems -a nextcloud -s false
    loginitems -a Quitter -s false
    loginitems -a "Time Out" -s false
    loginitems -a "Menubar Countdown" -s false
}
