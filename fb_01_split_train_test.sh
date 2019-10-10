#!/bin/bash
#
# A script that creates the fileids and transcriptions files inside the etc/
# folder and also create symlinks of the audio dataset within the wav folder
#
# Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: March 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference:
# https://cmusphinx.github.io/wiki/tutorialam/

DEGUB=false
SPLIT_RANDOM=false
dir_test="frases16k"

if test $# -ne 2
then
	echo "A script that creates the fileids and transcriptions files inside the etc/"
	echo "folder and also create symlinks of the audio dataset within the wav folder"
	echo
	echo "Usage: $0 <audio_dataset_dir> <sphinx_project_dir>"
	echo -e "\t<audio_dataset_dir> is the folder that contains all your audio base (wav + transcript.)."
	echo -e "\t<sphinx_project_dir> is the folder where you previously hosted your project."
	echo -e "\t                    e.g.: /home/cassio/sphinx/MEUPROJETO"
	exit 1
elif [ ! -d $1 ] || [ ! -d $2 ]
then
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
	if [[ $DEGUB == true ]] ; then echo -ne "defining $2 set: " ; fi
	n=$(cat ${2}.list.0 | wc -l)
	i=1
	while read line
	do
		# define the ID speaker (same name of the folder)
		spkr=$(readlink -f $line | sed 's/\// /g' | awk '{print $(NF-1)}')
		wavname=$(basename $line)

		# get the fullpath of audio and transcriptions files
		wav=$(readlink -f ${line}.wav) 
		txt=$(readlink -f ${line}.txt) 

		# execute process of creating symlinks in background
		(split_dataset_bg $1 $spkr $wav $txt)&

		#if [[ $DEGUB == true ]] ; then
		#	echo -ne "\r\t\t\t\t\t\t$i/$n"
		#	i=$((i+1))
		#fi
	done < ${2}.list.0
	#if [[ $DEGUB == true ]] ; then echo ; fi
	sleep 1
	echo -e "\ndone splitting $2"
}

# 1.) create fileids
function create_fileids() {
	dbname=$(basename $1)
	if [[ $DEGUB == true ]] ; then echo -ne "fileids for $2 set: " ; fi
	rm -f ${1}/etc/${dbname}_${2}.fileids
	n=$(cat ${2}.list.1 | wc -l)
	i=1
	while read line
	do
		# define the ID speaker (same name of the folder)
		spkr=$(readlink -f $line | sed 's/\// /g' | awk '{print $(NF-1)}')
		wavname=$(basename $line)

		# create etc/fileids
		echo "${spkr}/${wavname}" >> ${1}/etc/${dbname}_${2}.fileids

		if [[ $DEGUB == true ]]
		then
			echo -ne "\r\t\t\t\t\t\t$i/$n"
			i=$((i+1))
		fi
	done < ${2}.list.1
	if [[ $DEGUB == true ]] ; then echo ; fi
	sleep 1
	echo -e "\ndone fileids"
}


# 2.) create transcription files
function create_trans() {
	dbname=$(basename $1)
	if [[ $DEGUB == true ]] ; then echo -ne "transcription for $2 set: " ; fi
	rm -f ${1}/etc/${dbname}_${2}.transcription
	n=$(cat ${2}.list.2 | wc -l)
	i=1
	while read line
	do
		# define the ID speaker (same name of the folder)
		spkr=$(readlink -f $line | sed 's/\// /g' | awk '{print $(NF-1)}')
		wavname=$(basename $line)

		# get the fullpath transcriptions files
		txt=$(readlink -f ${line}.txt) 

		# create etc/transcription
		echo "<s> $(cat $txt | sed 's/ü/u/g') </s> ($wavname)" >> ${1}/etc/${dbname}_${2}.transcription

		echo -ne "\r\t\t\t\t\t\t$i/$n"
		i=$((i+1))
	done < ${2}.list.2
	echo
	#if [[ $DEGUB == true ]] ; then echo ; fi
	sleep 1
	echo -e "\ndone transcriptions"
}

### main ###

# sort -R would have solved this crap (while read line)
if [[ $SPLIT_RANDOM == true ]]
then
	echo -e "\033[1mshuffling dataset...\033[0m"
	find $1 -name '*.wav' | sed 's/.wav//g' |\
			while read line; do echo "$RANDOM $line" ; done |\
			sort | awk '{print $NF}' > filelist.tmp
	
	ntotal=$(cat filelist.tmp | wc -l)
	ntest=$((ntotal/10))     # 10% test
	ntrain=$((ntotal-ntest)) # 90% train
	
	head -n $ntrain filelist.tmp > train.list
	tail -n $ntest  filelist.tmp > test.list

	rm filelist.tmp
else
	echo "warning: using only '$dir_test' for test"
	find "${1}" -name '*.wav' | grep -v "${dir_test}" | sed 's/.wav//g' > train.list
	find "${1}/${dir_test}" -name '*.wav' | sed 's/.wav//g' > test.list

	ntrain=$(wc -l train.list | awk '{print $1}')
	ntest=$(wc -l test.list | awk '{print $1}')
fi

cp train.list train.list.0
cp train.list train.list.1
cp train.list train.list.2

cp test.list  test.list.0
cp test.list  test.list.1
cp test.list  test.list.2

rm train.list test.list

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
rm train.list.* test.list.*

#(play -q doc/KDE-Im-Sms.ogg)&
#notify-send "'$0' finished"
sleep 1
### EOF ###
