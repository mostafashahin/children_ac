#!/usr/bin/env python3

#Will use the transcrp.tbl file on the tabels directory

#The naming convention:
#mbak2dq2 --> [1ch m/f][3chs initials][1dig+2chs sentence ID][1dig 1/2 for good/poor speaker]

import pandas as pd
import numpy as np
import glob, sys
from os.path import join, isfile, splitext, basename, normpath
import argparse
import re

re.DOTALL

#There are different type of noise tags in the CMU kids trans files.
#Here each tag converted to a noise symbole.

lRemovedTags = ('[begin_crosstalk]','[begin_crosstalk_noise]','[begin_human_noise]','[begin_microphone_noise]','[begin_noise]',\
                '[begin_nosie]','[being_noise]','[crosstalk]','[cut]','[end_crosstalk]','[end_crosstalk_noise]','[end_human_noise]',\
                '[end_microphone_noise]','[end_noise]','[microphone_noise]','[noise]','[begin-crosstalk]','[begin-crosstalk-noise]',\
                '[begin-human-noise]','[begin-microphone-noise]','[begin-noise]','[begin-nosie]','[being-noise]','[end-crosstalk]',\
                '[end-crosstalk-noise]','[end-human-noise]','[end-microphone-noise]','[end-noise]','[microphone-noise]')
dSimpleReplace = dict([('[human_noise]','<noise>'),('[human_nosie]','<noise>'),('[whisper]','<whisper>'),('[yawn]','<yawn>'),\
                       ('[sil]','<pau>'),('[human-noise]','<noise>'),('[human-nosie]','<noise>')])



#Function to replace the tag with symbol, return first element in the dNoiseTag2Symb tuble if connected and second element if not

#Make sure that phonemes between // upper case and remove //
upper = lambda x : x.group(1).upper()

def replace_simple(match):
    return dSimpleReplace[match.group(0)]
def apply_re_on_txt(sTxt,lRe,isUpper=False):
    sContent = sTxt.lower()
    for ptrn,repl in lRe:
        sContent = ptrn.sub(repl,sContent)
    if isUpper:
        sContent = sContent.upper()
    return sContent

#TODO:Let function takes file names strings not file objects and open it as append
def get_global_files(sCMUKidsDir, fTxt, fUtt2Spk, fWavScp):
    
    #Regular Expression to normalize the text
    #p = re.compile('([\w\s]+)[\W](\s|$)')
    #rP_norm = re.compile('([\w\s]+)[\'\",\.](\s|$)|\*')
    Get_basename = lambda s : splitext(basename(s))[0]
    sDataDir = join(sCMUKidsDir,'kids')
    sTransFile = join(sCMUKidsDir,'tables','transcrp.tbl')
    with open(sTransFile,'r') as fTransFile:
        dTrans = dict([(t[0],' '.join(t[1:])) for t in map(lambda x: x.split(),fTransFile.read().splitlines())])

    #Get all speech files in Sph format
    lSphFiles = np.asarray(glob.glob(join(sDataDir,'**/*.sph'),recursive=True))
        
    lSphFileIDs = np.asarray(list(map(Get_basename,lSphFiles)))

    #Find wav files that have transcription
    lValidFiles = np.intersect1d(lSphFileIDs,list(dTrans.keys()),return_indices=True)
    
    #Update file list
    lSphFiles = lSphFiles[lValidFiles[1]]
    lSphFileIDs = lSphFileIDs[lValidFiles[1]]
    
    #Map noise tags
    rPtrn_Remove = re.compile('|'.join(map(re.escape,lRemovedTags)))
    rPtrn_Simple_Replace = re.compile('|'.join(map(re.escape,dSimpleReplace.keys())))
    rPtrn_whisper = re.compile('(\[begin_whiper\]|\[begin_whisper\]).*?(\[end_whiper\]|\[end_whisper\])')
    rPtrn_yawn = re.compile('\[begin_yawn\].*?\[end_yawn\]')
    rPtrn_post = re.compile('\[.*?\]|,')
    #We have here only 200 so just convert it to words and no need for normalization process 
    rPtrn_num = re.compile('200')
    rPtrn_upper = re.compile('/(.*?)/')

    lRe = ((rPtrn_Remove,' '),(rPtrn_Simple_Replace,replace_simple),(rPtrn_whisper,'<unk>'),(rPtrn_yawn,'<unk>'),(rPtrn_post,' '),(rPtrn_num,' two hundred '),(rPtrn_upper,upper))
    
    lTrans = [apply_re_on_txt(dTrans[t],lRe,False) for t in lSphFileIDs]


    lSpkrID = [t[0:4] for t in lSphFileIDs]
    lUttID = [t[4:7] for t in lSphFileIDs]

    
    for sSpkId, sUttId, sTrans, sSphFile in zip(lSpkrID, lUttID, lTrans, lSphFiles):
        print(sSpkId+'-'+sUttId, sTrans, file=fTxt)
        print(sSpkId+'-'+sUttId, sSpkId, file=fUtt2Spk)
        print(sSpkId+'-'+sUttId, 'sph2pipe -f wav -p -c 1 '+sSphFile+' |', file=fWavScp)
    return


def ArgParser():
    parser = argparse.ArgumentParser(description='This code for creating Kaldi files for CMU Kids dataset', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('CMU_Dir',  help='The path to the main directory of CMU DIR data', type=str)
    parser.add_argument('Text_File',  help='The path to the text file with <UttID> <Trans>', type=str)
    parser.add_argument('Utterance_to_Speakers_File',  help='The path to the Utterance to Speaker mapping file', type=str)
    parser.add_argument('Wav_Scp_File',  help='The path to the file contains list of wav files <RecID> <wavfile>', type=str)
    return parser.parse_args()

if __name__ == '__main__':
    args = ArgParser()
    sCMUDir, sTxt, sUtt2Spk, sWavScp = args.CMU_Dir, args.Text_File, args.Utterance_to_Speakers_File, args.Wav_Scp_File
    with open(sTxt,'a') as fTxt, open(sUtt2Spk,'a') as fUtt2Spk, open(sWavScp,'a') as fWavScp:
            get_global_files(sCMUDir, fTxt, fUtt2Spk, fWavScp)




    



