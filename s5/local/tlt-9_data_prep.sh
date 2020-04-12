#!/bin/bash

# Copyright (c) 2020, FBK 
# License: Apache 2.0

tlt_data_dir=
sup_sfx=sup

. ./utils/parse_options.sh 


#for d in train dev eval ; do
for d in train dev ; do

if ! test -d data/tlt-9/${d}
then
    mkdir -p data/tlt-9/${d}
else
    rm data/tlt-9/${d}/*.scp
fi

find -L ${tlt_data_dir}/audio/TLT2017${d} -name "*.wav" > data/tlt-9/${d}/wav.lst
if ! test -s data/tlt-9/${d}/wav.lst ; 
then 
    echo Error: no wav found in ${tlt_data_dir}/audio/TLT2017${d}
    exit
fi

for f in `cat data/tlt-9/${d}/wav.lst`;do echo `basename $f .wav` $f ; done  | sort > data/tlt-9/${d}/wav.scp
cat ${tlt_data_dir}/audio/TLT2017${d}.${sup_sfx} | sort > data/tlt-9/${d}/text

cut -d_ -f1 data/tlt-9/${d}/wav.scp > data/tlt-9/${d}/speakers
paste data/tlt-9/${d}/wav.scp data/tlt-9/${d}/speakers | awk '{print $1,$3}' > data/tlt-9/${d}/utt2spk
utils/utt2spk_to_spk2utt.pl data/tlt-9/${d}/utt2spk > data/tlt-9/${d}/spk2utt

utils/fix_data_dir.sh data/tlt-9/${d}

done

utils/copy_data_dir.sh data/tlt-9/train data/train_tlt-9
utils/copy_data_dir.sh data/tlt-9/dev data/dev_tlt

