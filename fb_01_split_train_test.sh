#!/bin/bash
#
# A script that creates the fileids and transcriptions files inside the etc/
# folder and also create symlinks of the audio dataset within the wav folder
#
# Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: March 2018
# cassio batista - https://cassota.gitlab.io/
#
# Reference:
# https://cmusphinx.github.io/wiki/tutorialam/

SPLIT_RANDOM=false
NJ=4
TEST_DIR="lapsbm16k"
SKIP_DIRS="tedx-*|male-female*"

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

if test $# -ne 2 ; then
    print_fb_ascii
    echo "Usage: $0 <audio_dataset_dir> <sphinx_project_dir>"
    echo -e "  <audio_dataset_dir>  is the folder that contains all your audio base (wav + transcript.)."
    echo -e "  <sphinx_project_dir> is the folder where you previously hosted your project."
    echo -e "                       e.g.: ${HOME}/sphinx/MEUPROJETO"
    exit 1
elif [ ! -d $1 ] || [ ! -d $2 ] ; then
    echo "Error: both '$1' and '$2' must be dirs"
    exit 1
fi

function split_dataset_bg() {
    # create a dir for the speaker and link both files to it
    mkdir -p ${1}/wav/${2}
    ln -s $3 ${1}/wav/${2}
    ln -s $4 ${1}/wav/${2} 
}

# 0.) split train test
function split_dataset() {
    if [ ! -d ${1}/wav ] || [ ! -d ${1}/etc ] ; then
        echo "warning: you may not had run the fb_00 script!"
    fi
    dbname=$(basename $1)
    rm -rf ${1}/wav
    while read line ; do
        # define the ID speaker (same name of the folder)
        spkr=$(readlink -f $line | sed 's/\// /g' | awk '{print $(NF-1)}')
        wavname=$(basename $line)

        # get the fullpath of audio and transcriptions files
        wav=$(readlink -f ${line}.wav) 
        txt=$(readlink -f ${line}.txt) 

        # execute process of creating symlinks in background
        (split_dataset_bg $1 $spkr $wav $txt)&

    done < ${2}.list.0
    sleep 1
    echo -e "\ndone splitting $2"
}

# 1.) create fileids
function create_fileids() {
    dbname=$(basename $1)
    rm -f ${1}/etc/${dbname}_${2}.fileids
    while read line ; do
        # define the ID speaker (same name of the folder)
        spkr=$(readlink -f $line | sed 's/\// /g' | awk '{print $(NF-1)}')
        wavname=$(basename $line)

        # create etc/fileids
        echo "${spkr}/${wavname}" >> ${1}/etc/${dbname}_${2}.fileids
    done < ${2}.list.1
    sleep 1
    echo -e "\ndone fileids"
}

# 2.) create transcription files
function create_trans() {
    dbname=$(basename $1)
    rm -f ${1}/etc/${dbname}_${2}.transcription
    while read line ; do
        # define the ID speaker (same name of the folder)
        spkr=$(readlink -f $line | sed 's/\// /g' | awk '{print $(NF-1)}')
        wavname=$(basename $line)

        # get the fullpath transcriptions files
        txt=$(readlink -f ${line}.txt) 

        # create etc/transcription
        echo "<s> $(cat $txt | sed 's/ü/u/g') </s> ($wavname)" >> ${1}/etc/${dbname}_${2}.transcription

    done < ${2}.list.2
    echo
    sleep 1
    echo -e "\ndone transcriptions"
}

### main ###
if $SPLIT_RANDOM ; then
    echo -en "\033[1m"
    echo "shuffling dataset..."
    echo -en "\033[0m"
    find "$1" -name '*.wav' | sed 's/.wav//g' | sort -R > filelist.tmp
    
    ntotal=$(cat filelist.tmp | wc -l)
    ntest=$((ntotal/10))     # 10% test
    ntrain=$((ntotal-ntest)) # 90% train
    
    head -n $ntrain filelist.tmp > train.list
    tail -n $ntest  filelist.tmp > test.list

    rm filelist.tmp
else
    echo "warning: using only '$TEST_DIR' for test"
    find "${1}" -name '*.wav' |\
            grep -v "${TEST_DIR}" | sed 's/.wav//g' > train.list
    find "${1}/${TEST_DIR}" -name '*.wav' | sed 's/.wav//g' > test.list

    ntrain=$(wc -l train.list | awk '{print $1}')
    ntest=$(wc -l test.list | awk '{print $1}')
fi

split -den $NJ --additional-suffix '.temp' train.list TRAIN
#split -den $NJ --additional-suffix '.temp' test.list  TEST

for f in $(ls TRAIN*.temp) ; do
    echo $f
done
exit 1
rm *.list

echo -e "\033[1msplitting dataset (bg)...\033[0m"
(split_dataset "$2" "test")&
(split_dataset "$2" "train")&
sleep 1

echo -e "\033[1mcreating fileids (bg)...\033[0m"
(create_fileids "$2" "test")&
(create_fileids "$2" "train")&
sleep 1

echo -ne "\033[1mcreating transcription files (fg)...\033[0m"
(create_trans "$2" "test")&
create_trans  "$2" "train"

echo -e "\e[1mDone!\e[0m"
rm TRAIN.*.temp TEST.*.temp

notify-send -i $(readlink -f doc/logo_fb_github_footer.png) \
    "'$0' finished" "check out your CMU Sphinx project dir at '$1'"
