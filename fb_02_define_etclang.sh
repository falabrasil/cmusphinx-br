#!/bin/bash
#
# A script that creates the language files inside the etc/ dir (.dic, .filler
# and .phone), except the language model, which must be created with SRILM in
# the ARPA format
#
# Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: March 2018
# cassio batista - https://cassota.gitlab.io/
#
# Reference:
# https://cmusphinx.github.io/wiki/tutorialam/

LM_LOCAL_PATH=${HOME}/fb-gitlab/fb-asr/fb-asr-resources/kaldi-resources/lm/lm.arpa

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
    echo "Usage: $0 <fb_nlp_path> <sphinx_project_dir>"
    echo "  <fb_nlp_path> is the folder where you cloned the repo 'nlp-generator.git'"
    echo "                e.g.: ${HOME}/fb-gitlab/fb-nlp/nlp-generator"
    echo "                ref.: https://gitlab.com/fb-nlp/nlp-generator.git"
    echo "  <sphinx_project_dir> is the folder where you previously hosted your project."
    echo "                       e.g.: ${HOME}/sphinx/MEUPROJETO"
    exit 1
elif [ ! -d $1 ] ; then
    echo "Error: '$1' must be a dir"
    exit 1
fi

# 0) create wordlist (this is rather a preproc step towards creating a phone dict)
# eight
# five
# four
# nine
function create_wordlist() {
    echo "creating wordlist (this stage is sequential, so be patient)..."
    for txt in $(find ${1}/wav/ -name *.txt) ; do
        for word in $(cat $txt) ; do
            echo $word >> wlist.tmp
        done 
    done
    sort wlist.tmp | uniq > wordlist.tmp
}

# 1) your_db.dic
# eight ey t
# five f ay v
# four f ao r
function create_dic() {
    dbname=$(basename $2)
    echo "creating '${dbname}.dic' file... "
    java -jar "${1}/fb_nlplib.jar" -i wordlist.tmp -o ${2}/etc/${dbname}.dic -ga
}

# 2) your_db.phone
# ah
# ao
# ay
# eh
function create_phone() {
    dbname=$(basename $1)
    echo -n "creating '${dbname}.phone' file... "

    cat ${1}/etc/${dbname}.dic | awk '{$1="" ; print}' > plist.tmp
    echo "SIL" > phonelist.tmp
    for phone in $(cat plist.tmp) ; do
        echo $phone >> phonelist.tmp
    done
    sort phonelist.tmp | uniq > ${1}/etc/${dbname}.phone
    echo
}

# 3) your_db.filler
# <s>   SIL
# </s>  SIL
# <sil> SIL
function create_filler() {
    dbname=$(basename $1)
    echo -n "creating '${dbname}.filler' file... "
    echo "<s>   SIL"  > ${1}/etc/${dbname}.filler
    echo "</s>  SIL" >> ${1}/etc/${dbname}.filler
    echo "<sil> SIL" >> ${1}/etc/${dbname}.filler
    echo
}

### MAIN ###
create_wordlist $2
create_dic   $1 $2
create_phone    $2
create_filler   $2

if [ -f $LM_LOCAL_PATH ] ; then
    cp -v $LM_LOCAL_PATH ${2}/etc/$(basename $2).lm
fi

echo -e "\e[1mDone!\e[0m"
rm *.tmp

notify-send -i $(readlink -f doc/logo_fb_github_footer.png) \
    "'$0' finished" "check out your CMU Sphinx project dir at '$1'"
### EOF ###
