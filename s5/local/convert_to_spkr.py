#!/usr/bin/env python3
import sys, re
i = 0
j = 1
bIvector = bool(int(sys.argv[4]))
bGotSpkr = False
bReplaced = False
affix='spk'

if bIvector:
    offset=2
else:
    offset=0

log = open('log.txt','w')
p = re.compile('(?<=\[\s)[0-9]*')
p2 = re.compile('(?<=dim=)[0-9]*')
p3 = re.compile('ks(?=[\w]*)')
with open(sys.argv[1],'r') as f:
    dspks = dict([ i.split() for i in f.read().splitlines()])
with open(sys.argv[2],'r') as f:
   dutt2spk = dict([ i.split() for i in f.read().splitlines()]) 
dim = sys.argv[3]
for line in sys.stdin:
    #print(line,file=log)
    if i == 0:
        nFrams = int(re.findall('(?<=<I1V>\s)[0-9]*',line)[0])
        utt = re.findall('.*?(?= )',line)[0]
        #print(utt)
        spk = dutt2spk[utt[:utt.rfind('-')]]
        #print(spk)
        print(utt,spk,file=log)
        line = line.replace(utt,affix+'-'+utt)
    elif i ==j*(nFrams+offset+2):
        try:
            utt = re.findall('(?<=</Nnet3Eg> )(.*?)(?= <Nnet3Eg>)',line)[0]
            spk = dutt2spk[utt[:utt.rfind('-')]]
            line = line.replace(utt,affix+'-'+utt)
            bGotSpkr = True
        except IndexError:
            spk = ''
    if i == j*(nFrams+offset+2) -1 :
        print(spk,dspks[spk],line,file=log)
        line = p.sub(dspks[spk],line)
        line = p2.sub(dim,line)
        print(line,file=log)
        bReplaced = True
    sys.stdout.write(line)
    if bGotSpkr and bReplaced:
        j += 1
        bGotSpkr = False
        bReplaced = False
    i += 1
log.close()
