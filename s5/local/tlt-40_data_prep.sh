#!/bin/bash

# Copyright (c) 2020, FBK 
# License: Apache 2.0

tlt_data_dir=
sup_sfx=sup

. ./utils/parse_options.sh 

dir=data/train_tlt-40
#for d in train dev eval ; do
if ! test -d $dir
then
    mkdir -p $dir
else
    rm $dir/*.scp
fi
find -L ${tlt_data_dir}/audio/TLT1618train -name "*.wav" > $dir/wav.lst

if ! test -s $dir/wav.lst ; 
then 
    echo Error: no wav found in ${tlt_data_dir}/audio/TLT2017${d}
    exit
fi
for f in `cat $dir/wav.lst`;do echo `basename $f .wav` $f ; done  | sort > $dir/wav.scp

cat ${tlt_data_dir}/TLT1618train.norm.trn | sort > $dir/text
cut -d- -f1 $dir/wav.scp > $dir/speakers

paste $dir/wav.scp $dir/speakers | awk '{print $1,$3}' > $dir/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt

utils/fix_data_dir.sh $dir


