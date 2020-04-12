#!/bin/bash
#
#This code for preparing the OGI kids data for kaldi ASR training
#Should be run from s5 directory

set -e

export LC_ALL=C #To make sure that the sorting of files will be performed in the same way as C++
ogi_data_dir=
train_spkrs=local/ogi_train_spkrs
test_spkrs=local/ogi_test_spkrs
dev_spkrs=local/ogi_dev_spkrs
data_prep_opt="-r -s"
ver=1,2,3 #The selected level of verification 
grads='0-10' #The selected grad range of children

trndir=data/train_ogi
tstdir=data/test_ogi
devdir=data/dev_ogi

#. ./path.sh || exit 1; # for KALDI_ROOT
. ./utils/parse_options.sh
mkdir -p $trndir $tstdir $devdir


[ ! -d $ogi_data_dir/docs ] && echo "Error: the OGI directory must contains docs directory" && exit 1;

#Split speakers among test dev train in 3 sep files each contain list of speakers
#Write code in the shell to generate 3 dir data/train data/test data/dev and modify the below code to accept list of spekers 

touch $trndir/spkrs $tstdir/spkrs $devdir/spkrs

#Split speakers to train, test and dev by default 15% for test, 15% dev and 70% training
#Can be modified by passing optional --train_portion float, --test_portion float, --dev_portion float to the command

[ -f $train_spkrs ] && [ -f $test_spkrs ] && [ -f $dev_spkrs ] || local/ogi_split_data.py $OGIROOT $train_spkrs $test_spkrs $dev_spkrs

cp $train_spkrs $trndir/spkrs
cp $test_spkrs $tstdir/spkrs
cp $dev_spkrs $devdir/spkrs

#local/ogi_gen_text_utt2spkr.py $OGIROOT $trndir/text $trndir/utt2spk $trndir/wav.scp -l $trndir/spkrs -v $ver -g $grads $data_prep_opt

for dir in $trndir $tstdir $devdir; do
    
    local/ogi_gen_text_utt2spkr.py $ogi_data_dir $dir/text $dir/utt2spk $dir/wav.scp -l $dir/spkrs -v $ver -g $grads $data_prep_opt 

done

for dir in $trndir $tstdir $devdir; do
    #Sort Files
    sort -o $dir/text $dir/text
    sort -o $dir/utt2spk $dir/utt2spk
    sort -o $dir/wav.scp $dir/wav.scp

    utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt
    utils/fix_data_dir.sh $dir

done
