#!/bin/bash

myst_data_dir=/srv/scratch/z5173707/Dataset/MyST/

. ./utils/parse_options.sh 


cat ${myst_data_dir}/doc/trans_wav.lst | sed "s;PATHTODATA;$myst_data_dir/data;g" |  while read f; do [ -f $f ] && echo $f; done > myst_wav.lst

#if ! test -s myst_wav.lst ;
#then
#    echo Error: no wav found in ${myst_data_dir}/data
#    exit
#fi
#for d in train dev eval ; do
for d in train dev test; do

if ! test -d data/${d}_myst
then
    mkdir -p data/${d}_myst
else
    rm data/${d}_myst/*.scp
fi
grep -f $myst_data_dir/doc/spkrs_${d} myst_wav.lst | while read f; do echo $(basename $f .wav) $f; done | sort > data/${d}_myst/wav.scp
grep -f $myst_data_dir/doc/spkrs_${d} $myst_data_dir/doc/text > data/${d}_myst/text
cut -d'_' -f1,2 data/${d}_myst/wav.scp > data/${d}_myst/speakers

paste data/${d}_myst/wav.scp data/${d}_myst/speakers | awk '{print $1,$3}' > data/${d}_myst/utt2spk
utils/utt2spk_to_spk2utt.pl data/${d}_myst/utt2spk > data/${d}_myst/spk2utt

utils/fix_data_dir.sh data/${d}_myst

done

