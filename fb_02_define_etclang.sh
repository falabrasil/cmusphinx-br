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

TAG="FB_02"

# NOTE: update this path to point to a LM file in arpa format or either comment
# it or leave it blank to download our LM from GitLab's remote repo server
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
    echo -en "\033[1m"
    echo "[$TAG] creating wordlist (this stage is sequential, so be patient)..."
    echo -en "\033[0m"
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
    echo -en "\033[1m"
    echo "[$TAG] creating '${dbname}.dic' file... "
    echo -en "\033[0m"
    java -jar "${1}/fb_nlplib.jar" -i wordlist.tmp -o ${2}/etc/${dbname}.dic -ga
}

# 2) your_db.phone
# ah
# ao
# ay
# eh
function create_phone() {
    dbname=$(basename $1)
    echo -en "\033[1m"
    echo "[$TAG] creating '${dbname}.phone' file... "
    echo -en "\033[0m"
    cat ${1}/etc/${dbname}.dic | awk '{$1="" ; print}' > plist.tmp
    echo "SIL" > phonelist.tmp
    for phone in $(cat plist.tmp) ; do
        echo $phone >> phonelist.tmp
    done
    sort phonelist.tmp | uniq > ${1}/etc/${dbname}.phone
}

# 3) your_db.filler
# <s>   SIL
# </s>  SIL
# <sil> SIL
function create_filler() {
    dbname=$(basename $1)
    echo -en "\033[1m"
    echo "[$TAG] creating '${dbname}.filler' file... "
    echo -en "\033[0m"
    echo "<s>   SIL"  > ${1}/etc/${dbname}.filler
    echo "</s>  SIL" >> ${1}/etc/${dbname}.filler
    echo "<sil> SIL" >> ${1}/etc/${dbname}.filler
}

# 4) your_db.lm
function create_lm() {
    dbname=$(basename $1)
    echo -en "\033[1m"
    echo "[$TAG] creating '${dbname}.lm' file... "
    echo -en "\033[0m"
    if [ ! -z $LM_LOCAL_PATH ] &&  [ -f $LM_LOCAL_PATH ] ; then
        ln -sfv $LM_LOCAL_PATH ${1}/etc/${dbname}.lm
    else
        # FIXME does this overwrite a previously created symlink?
        wget -q --show-progress -O "${1}/etc/${dbname}.lm" \
            https://gitlab.com/fb-asr/fb-asr-resources/kaldi-resources/raw/master/lm/lm.arpa
    fi
}

### MAIN ###
create_wordlist $2
create_dic   $1 $2
create_phone    $2
create_filler   $2
create_lm       $2

echo -en "\033[1m"
echo "[$TAG] done!"
echo -en "\033[0m"
rm *.tmp

(play -q "/usr/share/sounds/freedesktop/stereo/complete.oga")&
notify-send -i $(readlink -f doc/logo_fb_github_footer.png) -t 8000 \
    "'$0' finished" "check out your project at '$1'"
