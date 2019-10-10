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

DATA_DIR="$1"
basefilename=$(basename $DATA_DIR)

mkdir -p $DATA_DIR
cd $DATA_DIR

mkdir etc
touch etc/${basefilename}{.dic,.phone,.lm.DMP,.filler}
touch etc/${basefilename}{_train.fileids,_train.transcription}
touch etc/${basefilename}{_test.fileids,_test.transcription}

mkdir wav

tree $DATA_DIR
echo "check out your project dir at '$(readlink -f $DATA_DIR)'"
### EOF ###
