#!/bin/bash

# Copyright (c) 2020, UNSW 
# License: Apache 2.0

. ./cmd.sh
. ./path.sh

#if [ -z "${TLT2020}" ] ; then
#    echo Error: please set variable TLT2020
#    echo
#    exit
#fi

nj=16
decode_nj=16
stage=1
train_set=train-cu
test_sets="dev_cmu dev_ogi dev_myst dev_tlt dev_cu test_ogi test_myst test_cmu test_cu"
lang=data/lang
ngr=4
lm_train=${TLT2020}/texts/TLT16W17train.trn.txt
lm_dev=${TLT2020}/texts/TLT2017dev.trn.txt
lm_dir=data/local/srilm
oov_symbol="<unk>"
dnn_stage=0
train_stage=-10
src_mdl=
datasets="ogi tlt-9 tlt-40 myst cmu cu"
# End configuration section
. ./utils/parse_options.sh

set -e # exit on error

if [ $stage -le 1 ]; then
  if [ ! -d  data/train ] ; then
      echo "$0:  ... preparing data folders"
      local/data_prep_all.sh --datasets "$datasets" 
  fi
fi

if [ $stage -le 2 ]; then
  echo "$0:  ... preparing dict and lang"
  local/prepare_dict.sh --datasets "$datasets"

  utils/prepare_lang.sh --share-silence-phones true \
    data/local/dict "$oov_symbol" data/local/lang data/lang

fi
if [ $stage -le 3 ]; then

    echo "$0:  ... preparing language model"
    ./local/prepare_lm.sh --ngr ${ngr} --lm-dir ${lm_dir} --oov-symbol $oov_symbol

fi
if [ $stage -le 4 ]; then
  # Now make MFCC features.
  # mfccdir should be some place with a largish disk where you
  # want to store MFCC features.
  mfccdir=mfcc #MOSTAFA The script dosen't use that, just the default 
  for x in ${test_sets} ${train_set}; do
      steps/make_mfcc.sh --nj ${nj} data/$x 
      steps/compute_cmvn_stats.sh data/$x 
      utils/fix_data_dir.sh data/$x
  done

fi

if [ $stage -le 5 ]; then
  # Starting basic training on MFCC features
  steps/train_mono.sh --nj $nj \
		      data/${train_set} ${lang} exp/mono
fi
if [ $stage -le 6 ]; then
  steps/align_si.sh --nj $nj  \
	  data/${train_set} ${lang} exp/mono exp/mono_ali

  steps/train_deltas.sh \
			4000 70000 \
			data/${train_set} ${lang} exp/mono_ali exp/tri1
fi

if [ $stage -le 7 ]; then
  steps/align_si.sh --nj $nj  \
		    data/${train_set} ${lang} exp/tri1 exp/tri1_ali

  steps/train_lda_mllt.sh  \
			  6000 140000 data/${train_set} ${lang} exp/tri1_ali exp/tri2
fi

if [ $stage -le 8 ]; then
  steps/align_si.sh --nj $nj  \
		    data/${train_set} ${lang} exp/tri2 exp/tri2_ali

  steps/train_sat.sh  \
		     11000 200000 data/${train_set} ${lang} exp/tri2_ali exp/tri3
fi
echo "${train_set}" "${test_sets}"
if [ $stage -le 9 ]; then
      local/chain/run_cnn_tdnn_2.sh \
        --train-stage $train_stage \
        --stage ${dnn_stage} \
        --nj ${nj} \
        --train-set "${train_set}" --test-sets "${test_sets}" \
        --gmm tri3 --nnet3-affix ""  
fi 
