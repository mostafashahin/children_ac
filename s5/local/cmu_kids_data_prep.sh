#!/bin/bash
#
#This code for preparing the CMU kids data for kaldi ASR training
#Should be run from s5 directory
cmu_data_dir=
train_spkrs=local/cmu_train_spkrs
test_spkrs=local/cmu_test_spkrs
dev_spkrs=local/cmu_dev_spkrs

trndir=data/train_cmu
tstdir=data/test_cmu
devdir=data/dev_cmu
set -e

export LC_ALL=C #To make sure that the sorting of files will be performed in the same way as C++

. ./utils/parse_options.sh

mkdir -p $trndir $tstdir $devdir

#. ./path.sh || exit 1; # for KALDI_ROOT

[ -f $train_spkrs ] && [ -f $test_spkrs ] && [ -f $dev_spkrs ] || (echo 'The speakers lists missing...' && exit 1)

cp $train_spkrs $trndir/spkrs
cp $test_spkrs $tstdir/spkrs
cp $dev_spkrs $devdir/spkrs

#Generate text, utt2spk, wav.scp files for the whole dataset
local/cmu_gen_text_utt2spkr.py $cmu_data_dir data/cmu_tmp_text data/cmu_tmp_utt2spk data/cmu_tmp_wav.scp

for dir in $trndir $tstdir $devdir; do

    cat $dir/spkrs | xargs -I{} echo ^{} | grep -f - data/cmu_tmp_utt2spk > $dir/utt2spk
    cat $dir/spkrs | xargs -I{} echo ^{} | grep -f - data/cmu_tmp_wav.scp > $dir/wav.scp

    if [ "$dir" == "$trndir" ]; then
      cat $dir/spkrs | xargs -I{} echo ^{} | grep -f - data/cmu_tmp_text > $dir/text
    else
      cut $dir/wav.scp -d' ' -f1 > $dir/utt.list
      cut $dir/utt.list -d'-' -f2 | xargs -I{} grep {} $cmu_data_dir/tables/sentence.tbl | cut -f3 | dos2unix | paste $dir/utt.list - > $dir/text
    fi

    sort -o $dir/text $dir/text
    sort -o $dir/utt2spk $dir/utt2spk
    sort -o $dir/wav.scp $dir/wav.scp

    utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt
    utils/fix_data_dir.sh $dir
done
