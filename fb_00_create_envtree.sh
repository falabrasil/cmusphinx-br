#!/bin/bash
#
# Create environment tree for training acoustic models with CMU Sphinx
#
# Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: Mar 2018
# cassio batista - https://cassota.gitlab.io/
#
# Reference: 
# https://cmusphinx.github.io/wiki/tutorialam/

TAG="FB_00"

function print_fb_ascii() {
    echo -e "\033[94m  ____                         \033[93m _____     _           \033[0m"
    echo -e "\033[94m / ___| _ __ _   _ _ __   ___  \033[93m|  ___|_ _| | __ _     \033[0m"
    echo -e "\033[94m| |  _ | '__| | | | '_ \ / _ \ \033[93m| |_ / _\` | |/ _\` |  \033[0m"
    echo -e "\033[94m| |_| \| |  | |_| | |_) | (_) |\033[93m|  _| (_| | | (_| |    \033[0m"
    echo -e "\033[94m \____||_|   \__,_| .__/ \___/ \033[93m|_|  \__,_|_|\__,_|    \033[0m"
    echo -e "                  \033[94m|_|      \033[32m ____                _ _\033[0m\033[91m  _   _ _____ ____    _   \033[0m"
    echo -e "                           \033[32m| __ ) _ __ __ _ ___(_) |\033[0m\033[91m| | | |  ___|  _ \  / \          \033[0m"
    echo -e "                           \033[32m|  _ \| '_ / _\` / __| | |\033[0m\033[91m| | | | |_  | |_) |/ ∆ \        \033[0m"
    echo -e "                           \033[32m| |_) | | | (_| \__ \ | |\033[0m\033[91m| |_| |  _| |  __// ___ \        \033[0m"
    echo -e "                           \033[32m|____/|_|  \__,_|___/_|_|\033[0m\033[91m \___/|_|   |_|  /_/   \_\       \033[0m"
    echo -e "                                     https://ufpafalabrasil.gitlab.io/"
    echo
}

if test $# -ne 1 ; then
    print_fb_ascii
    echo "Usage: $0 <proj_dir>"
    echo -e "  <proj_dir> must be the path for your project folder"
    echo -e "             e.g.: ${HOME}/sphinx/MEUPROJETO"
    exit 1
elif [ -d $1 ] ; then
    echo -n "'$1' exists as dir. Override? [y/N] "
    read ans
    if [[ "$ans" != "y" ]] ; then
        echo "aborted."
        exit 0
    else
        rm -rf $1
    fi
fi

# check for dependences
for f in sox wget ; do
    if ! $(type -t "$f" > /dev/null) ; then
        echo "[$TAG] please install '$f'"
        exit 1
    fi
done

mkdir -p $1
mkdir ${1}/{wav,etc}

basefilename=$(basename $1)
touch ${1}/etc/${basefilename}{.dic,.phone,.lm,.filler}
touch ${1}/etc/${basefilename}{_train.fileids,_train.transcription}
touch ${1}/etc/${basefilename}{_test.fileids,_test.transcription}

tree $1
echo -en "\033[1m"
echo "[$TAG] check out your project dir at '$(readlink -f $1)'"
echo -en "\033[0m"
