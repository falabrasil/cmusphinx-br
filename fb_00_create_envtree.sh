#!/bin/bash
#
# Create environment tree for training acoustic models with CMU Sphinx
#
# Grupo FalaBrasil (2018)
# Federal University of Pará (UFPA)
#
# Author: Mar 2018
# Cassio Batista - cassio.batista.13@gmail.com
#
# Reference: 
# https://cmusphinx.github.io/wiki/tutorialam/

if test $# -ne 1
then
	echo "A script to create the environment tree for training acoustic models"
	echo "according to CMUSphinx's pattern."
	echo "Ref.: https://cmusphinx.github.io/wiki/tutorialam/"
	echo
	echo "Usage: $0 <proj_dir>"
	echo -e "\t<proj_dir> must be the path for your project folder"
	echo -e "\te.g.: /home/cassio/sphinx/MEUPROJETO"
	exit 1
elif [ -d $1 ]
then
	echo -n "'$1' exists as dir. Override? [y/N] "
	read ans
	if [[ "$ans" != "y" ]] 
	then
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
