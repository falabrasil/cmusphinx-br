#!/usr/bin/env python3
# coding: utf-8
#
# this script uses a crossword dictionary to make transcriptions
# which use internal words to use crosswords
#
# Grupo FalaBrasil (2020)
# Universidade Federal do Pará (UFPA)
#
# author: feb 2020
# Daniel Santana - daniel.santana.1661@gmail.com

import sys

def makeDict(crossDPath, in2cross):
    with open(crossDPath, 'r') as crossDict:
        for line in crossDict:
            if ',' in line:
                word = line.split('\t')[0]
                in2cross[' ' + word.replace(',',' ') + ' '] = ' ' + word + ' '

def loadTrans(transPath):
    with open(transPath, 'r') as f:
        return f.read()

def writeTrans(writeTo, writeThis):
    with open(writeTo, 'w') as f:
        f.write(writeThis)

def errorMsg():
    print('This script must not be run by user')
    exit(1)

def main():
    if len(sys.argv) != 3: errorMsg()
    amPath    = sys.argv[1]
    amName    = sys.argv[2]

    base      = '{}/etc/{}'.format(amPath, amName)
    crossDict = '{}.dic'.format(base)
    trainPath = '{}_train.transcription'.format(base)
    testPath  = '{}_test.transcription'.format(base)

    dictionary = {}
    makeDict(crossDict, dictionary)

    trainText = loadTrans(trainPath)
    testText = loadTrans(testPath)

    for key in dictionary.keys():
        trainText = trainText.replace(key, dictionary[key])
        testText = testText.replace(key, dictionary[key])

    writeTrans(trainPath, trainText)
    writeTrans(testPath, testText)

if __name__ == '__main__':
    main()
