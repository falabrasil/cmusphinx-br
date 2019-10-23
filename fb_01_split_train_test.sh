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

NJ=6
SPLIT_RANDOM=false
TEST_DIR="lapsbm16k"
SKIP_DIRS="tedx|male-female|Anderson|lapsmail|alcaim" # TIP: add "alcaim" to speedup debugging
STAGE=0
SUBSETS_PREFIX=("train" "test") # TODO asset length==2

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
    echo "  <audio_dataset_dir>  is the folder that contains all your audio base (wav + transcript.)."
    echo "  <sphinx_project_dir> is the folder where you previously hosted your project."
    echo "                       e.g.: ${HOME}/sphinx/MEUPROJETO"
    exit 1
elif [ ! -d $1 ] || [ ! -d $2 ] ; then
    echo "Error: both '$1' and '$2' must be dirs"
    exit 1
fi

# https://askubuntu.com/questions/674333/how-to-pass-an-array-as-function-argument
# wait to background processes to finish (oct 17, 2019)
function wait_for_processes() {
    PIDS=("$@")
    echo -n "  done: "
    sleep 3
    for pid in ${PIDS[@]} ; do
        while [[ ! -z "$(ps --no-headers -p $pid)" ]] ; do
            sleep 10
            continue
        done
        echo -n "$pid "
    done
    echo
}

# 0.) split train test (oct 10, 2019)
# args: <file_list> <sphinx_project_dir>
function split_dataset() {
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
}

# 1.) create fileids (oct 12, 2019)
# args: <file_list> <sphinx_project_dir> <train_or_test>
# egs.:
#   speaker_1/file_1
#   speaker_2/file_2
function create_fileids() {
    fout=$(echo $1 | sed 's/\.in/\.fileids.out/g')
    rm -f $fout
    while read line ; do
        # define the ID speaker (same name of the folder)
        # get the filename of wav audio file
        spkr=$(basename $(dirname $line))
        wav=$(basename $line)
        echo "${spkr}/${wav}" >> $fout
    done < $1
}

# 2.) create transcription files (oct 12, 2019)
# args: <file_list> <sphinx_project_dir> <train_or_test>
# egs.:
#   <s> hello world </s> (file_1)
#   <s> foo bar </s> (file_2)
function create_transcription() {
    fout=$(echo $1 | sed 's/\.in/\.transcription.out/g')
    rm -f $fout
    while read line ; do
        # get the filename of wav audio file
        # get the fullpath of transcriptions files
        wav=$(basename $line)
        txt=$(readlink -f ${line}.txt) # FIXME readlink really necessary?
        echo "<s> $(cat $txt) </s> ($wav)" >> $fout
    done < $1
}

### main ###
if $SPLIT_RANDOM ; then
    echo -en "\033[1m"
    echo "shuffling dataset..."
    echo -en "\033[0m"
    find "$1" -name '*.wav' | sed 's/.wav//g' | sort -R > filelist.tmp
    
    ntotal=$(wc -l filelist.tmp | awk '{print $1}')
    ntest=$((ntotal/10))     # 10% test
    ntrain=$((ntotal-ntest)) # 90% train
    
    head -n $ntrain filelist.tmp > ${SUBSETS_PREFIX[0]}.list
    tail -n $ntest  filelist.tmp > ${SUBSETS_PREFIX[1]}.list

    rm filelist.tmp
else
    echo -en "\033[1m"
    echo "using only '$TEST_DIR' for test"
    echo "dir strings to skip: '$SKIP_DIRS'"
    echo -en "\033[0m"
    find "${1}" -name '*.wav' |\
            grep -vE "${TEST_DIR}|${SKIP_DIRS}" | sed 's/.wav//g' > ${SUBSETS_PREFIX[0]}.list
    find "${1}/${TEST_DIR}" -name '*.wav' | sed 's/.wav//g' > ${SUBSETS_PREFIX[1]}.list
fi

# falabrasil requirement for speed up efficiency
# split list of files into multiple files of list of files for parallel 
# processing with no bottleneck / queueing
if [ $STAGE -eq 0 ] ; then
    echo -en "\033[1m"
    echo "creating >$NJ< temp files for parallel processing jobs..."
    echo -en "\033[0m"
    split -de -a 3 -n l/${NJ} --additional-suffix '.split.in' ${SUBSETS_PREFIX[0]}.list "${SUBSETS_PREFIX[0]}_"
    split -de -a 3 -n l/${NJ} --additional-suffix '.split.in' ${SUBSETS_PREFIX[1]}.list "${SUBSETS_PREFIX[1]}_"
    rm *.list
    STAGE=$((STAGE+1))
fi

# falabrasil requirement for precaution:
# creating symlinks for wav and txt files in order to avoid messing up with real
# data on its original directory
if [ $STAGE -eq 1 ] ; then
    rm -rf ${2}/wav
    for prefix in ${SUBSETS_PREFIX[@]} ; do
        echo -en "\033[1m"
        echo "creating symlinks for $prefix dataset..."
        echo -en "\033[0m"
        PIDS=()
        echo -n "  pids: "
        for i in $(seq -f "%03g" 0 $((NJ-1))); do
            filename="${prefix}_${i}.split.in"
            (split_dataset $filename $2)& 
            PIDS+=($!)
            echo -n "$! "
        done
        echo
        wait_for_processes "${PIDS[@]}"
    done
    STAGE=$((STAGE+1))
fi

# cmu sphinx requirement:
# create .fileids files
if [ $STAGE -eq 2 ] ; then
    for prefix in ${SUBSETS_PREFIX[@]} ; do
        echo -en "\033[1m"
        echo "creating .fileids file for $prefix dataset..."
        echo -en "\033[0m"
        PIDS=()
        echo -n "  pids: "
        for i in $(seq -f "%03g" 0 $((NJ-1))); do
            filename="${prefix}_${i}.split.in"
            (create_fileids $filename $2 $prefix)& 
            PIDS+=($!)
            echo -n "$! "
        done
        echo
        wait_for_processes "${PIDS[@]}"

        # merge files created in bg into .fileids output file
        fileids=${2}/etc/$(basename $2)_${prefix}.fileids
        rm -f $fileids
        for i in $(seq -f "%03g" 0 $((NJ-1))); do
            filename="${prefix}_${i}.split.fileids.out"
            cat $filename >> $fileids
        done
    done
    STAGE=$((STAGE+1))
fi

# cmu sphinx requirement
# create .transcription files
if [ $STAGE -eq 3 ] ; then
    for prefix in ${SUBSETS_PREFIX[@]} ; do
        echo -en "\033[1m"
        echo "creating .transcription file for $prefix dataset..."
        echo -en "\033[0m"
        PIDS=()
        echo -n "  pids: "
        for i in $(seq -f "%03g" 0 $((NJ-1))); do
            filename="${prefix}_${i}.split.in"
            (create_transcription $filename $2 $prefix)& 
            PIDS+=($!)
            echo -n "$! "
        done
        echo
        wait_for_processes "${PIDS[@]}"

        # merge files created in bg into .transcription output file
        transcription=${2}/etc/$(basename $2)_${prefix}.transcription
        rm -f $transcription
        for i in $(seq -f "%03g" 0 $((NJ-1))); do
            filename="${prefix}_${i}.split.transcription.out"
            cat $filename >> $transcription
        done
    done
    STAGE=$((STAGE+1))
fi

echo -en "\033[1m"
echo "done!"
echo -en "\033[0m"

#rm -f *.temp *.split.*.in *.split.*.out *.tmp

notify-send -i $(readlink -f doc/logo_fb_github_footer.png) \
    "'$0' finished" "it's time to run fb_02. check out your CMU Sphinx project dir at '$1'"
