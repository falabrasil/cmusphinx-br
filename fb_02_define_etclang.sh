#!/bin/bash
#
# A script that creates the language files inside the etc/ dir (.dic, .filler
# and .phone), except the language model, which must be created with SRILM in
# the ARPA format
#
# Copyleft Grupo FalaBrasil (2018)
#
# Author: March 2018
# Cassio Batista - cassio.batista.13@gmail.com
# Federal University of Pará (UFPA)
#
# Reference:
# https://cmusphinx.github.io/wiki/tutorialam/

if test $# -ne 1
then
	echo "A script that creates the language files inside the etc/ dir "\
			"(.dic, .filler and .phone), except the language model, "\
			"which is created by SRILM."
	echo
	echo "Usage: $0 <sphinx_project_dir>"
	echo -e "\t<sphinx_project_dir> is the folder where you previously "\
			"hosted your project."
	echo -e "\t                    e.g.: ${HOME}/sphinx/MEUPROJETO"
	echo
	echo "NOTE: If you have downloaded the dict from our github" \
				"you DO NOT need to perform this step."
	echo "Check it out: https://github.com/falabrasil/phonetic-dicts/"

	exit 1
elif [ ! -d $1 ] 
then
	echo "Error: '$1' must be a dir"
	exit 1
fi

# 0) create wordlist
# eight
# five
# four
# nine
function create_wordlist() {
	echo "creating wordlist..."
	for txt in $(find ${1}/wav/ -name *.txt)
	do
		for word in $(cat $txt)
		do
			echo $word >> wlist.tmp
		done 
	done
	cat wlist.tmp | sort | uniq > wordlist.tmp
}

# 1) your_db.dic
# eight ey t
# five f ay v
# four f ao r
function create_dic() {
	dbname=$(basename $1)
	echo -n "creating '${dbname}.dic' file... "

	[[ -z "$(which lapsg2p)" ]] && echo "error: g2p must be installed" && exit 1
	lapsg2p -w wordlist.tmp -d dict.tmp >/dev/null 2>&1

	python convert_dict_to_ascii.py dict.tmp ${1}/etc/${dbname}.dic 
	echo
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
	for phone in $(cat plist.tmp)
	do
		echo $phone >> phonelist.tmp
	done
	cat phonelist.tmp | sort | uniq > ${1}/etc/${dbname}.phone
	echo
}

# 3) your_db.filler
# <s>   SIL
# </s>  SIL
# <sil> SIL
function create_filler() {
	dbname=$(basename $1)
	echo -n "creating '${dbname}.filler' file... "
	echo "<s> SIL"    > ${1}/etc/${dbname}.filler
	echo "</s> SIL"  >> ${1}/etc/${dbname}.filler
	echo "<sil> SIL" >> ${1}/etc/${dbname}.filler
	echo
}

### MAIN ###
create_wordlist $1
create_dic $1
create_phone $1
create_filler $1

echo -e "\e[1mDone!\e[0m"
rm *.tmp

(play -q doc/KDE-Im-Sms.ogg)&
notify-send "'$0' finished"
### EOF ###
