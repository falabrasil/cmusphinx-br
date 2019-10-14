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
NJ=6
TEST_DIR="lapsbm16k"
SKIP_DIRS="tedx|male-female|base_Anderson|lapsmail"
STAGE=0

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

function wait_for_process() {
    for pid in ${1[@]} ; do
        echo $pid
    done
}

# 0.) split train test (oct 10, 2019)
# args: <file_list> <sphinx_project_dir>
function split_dataset() {
    rm -rf ${2}/wav
    while read line ; do
        # define the ID speaker (same name of the folder)
        # get the fullpath of audio and transcriptions files
        spkr=$(basename $(dirname $line))
        wav=$(readlink -f ${line}.wav) 
        txt=$(readlink -f ${line}.txt) 

        # define symlinks
        mkdir -p ${2}/wav/${spkr}
        ln -s $wav ${2}/wav/${spkr}
        ln -s $txt ${2}/wav/${spkr} 
    done < $1
    sleep 1
    echo -e "done splitting $1 ($(date))"
}

# 1.) create fileids (oct 12, 2019)
# args: <file_list> <sphinx_project_dir> <train_or_test>
# egs.:
#   speaker_1/file_1
#   speaker_2/file_2
function create_fileids() {
    fout=${2}/etc/$(basename $2)_${3}.fileids
    rm -f $fout
    while read line ; do
        # define the ID speaker (same name of the folder)
        # get the filename of wav audio file
        spkr=$(basename $(dirname $line))
        wav=$(basename $line)
        echo "${spkr}/${wav}" >> $fout
    done < $1
    sleep 1
    echo -e "done creating .fileids from $1 ($(date))"
}

# 2.) create transcription files (oct 12, 2019)
# args: <file_list> <sphinx_project_dir> <train_or_test>
# egs.:
#   <s> hello world </s> (file_1)
#   <s> foo bar </s> (file_2)
function create_transcription() {
    fout=${2}/etc/$(basename $2)_${3}.transcription
    rm -f $fout
    while read line ; do
        # get the filename of wav audio file
        # get the fullpath of transcriptions files
        wav=$(basename $line)
        txt=$(readlink -f ${line}.txt) # FIXME readlink really necessary?
        echo "<s> $(cat $txt) </s> ($wav)" >> $fout
    done < $1
    sleep 1
    echo -e "done creating ,transcription from $1 ($(date))"
}

### main ###
if [ $STAGE -eq 0 ] ; then
    if $SPLIT_RANDOM ; then
        echo -en "\033[1m"
        echo "shuffling dataset..."
        echo -en "\033[0m"
        find "$1" -name '*.wav' | sed 's/.wav//g' | sort -R > filelist.tmp
        
        ntotal=$(wc -l filelist.tmp | awk '{print $1}')
        ntest=$((ntotal/10))     # 10% test
        ntrain=$((ntotal-ntest)) # 90% train
        
        head -n $ntrain filelist.tmp > train.list
        tail -n $ntest  filelist.tmp > test.list
    
        rm filelist.tmp
    else
        echo -en "\033[1m"
        echo "using only '$TEST_DIR' for test"
        echo "dir strings to skip: '$SKIP_DIRS'"
        echo -en "\033[0m"
        find "${1}" -name '*.wav' |\
                grep -vE "${TEST_DIR}|${SKIP_DIRS}" | sed 's/.wav//g' > train.list
        find "${1}/${TEST_DIR}" -name '*.wav' | sed 's/.wav//g' > test.list
    fi
    STAGE=$((STAGE+1))
fi

if [ $STAGE -eq 1 ] ; then
    echo -en "\033[1m"
    echo "creating $NJ temp files for parallel processing jobs..."
    echo -en "\033[0m"
    split -den l/${NJ} --additional-suffix '.temp' train.list TRAIN
    split -den l/${NJ} --additional-suffix '.temp' test.list  TEST
    rm *.list
    STAGE=$((STAGE+1))
fi

if [ $STAGE -eq 2 ] ; then
    echo -en "\033[1m"
    echo "creating symlinks for test dataset..."
    echo -en "\033[0m"
    PIDS=()
    for f in $(ls TEST*.temp) ; do
        (split_dataset $f $2)& 
        PIDS+=($!)
    done
    
    # TODO check PIDs and wait for bg processes to finish
    STAGE=$((STAGE+1))
fi

if [ $STAGE -eq 3 ] ; then
    echo -en "\033[1m"
    echo "creating symlinks for train dataset..."
    echo -en "\033[0m"
    PIDS=()
    for f in $(ls TRAIN*.temp) ; do
        (split_dataset $f $2)& 
        PIDS+=($!)
    done
    
    # TODO check PIDs and wait for bg processes to finish
    STAGE=$((STAGE+1))
fi

if [ $STAGE -eq 4 ] ; then
    echo -en "\033[1m"
    echo "creating .fileids file for test dataset..."
    echo -en "\033[0m"
    PIDS=()
    for f in $(ls TEST*.temp) ; do
        (create_fileids $f $2 "test")& 
        PIDS+=($!)
    done
    
    # TODO check PIDs and wait for bg processes to finish
    STAGE=$((STAGE+1))
fi

if [ $STAGE -eq 5 ] ; then
    echo -en "\033[1m"
    echo "creating .fileids file for train dataset..."
    echo -en "\033[0m"
    PIDS=()
    for f in $(ls TRAIN*.temp) ; do
        (create_fileids $f $2 "train")& 
        PIDS+=($!)
    done
    
    # TODO check PIDs and wait for bg processes to finish
    STAGE=$((STAGE+1))
fi

if [ $STAGE -eq 6 ] ; then
    echo -en "\033[1m"
    echo "creating .transcription file for test dataset..."
    echo -en "\033[0m"
    PIDS=()
    for f in $(ls TEST*.temp) ; do
        (create_transcription $f $2 "test")& 
        PIDS+=($!)
    done
    
    # TODO check PIDs and wait for bg processes to finish
    STAGE=$((STAGE+1))
fi

echo -en "\033[1m"
echo "done!"
echo -en "\033[0m"
rm TRAIN*.temp TEST*.temp

notify-send -i $(readlink -f doc/logo_fb_github_footer.png) \
    "'$0' finished" "check out your CMU Sphinx project dir at '$1'"
