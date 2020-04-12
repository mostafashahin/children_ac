#!/usr/bin/env bash

# Copyright Johns Hopkins University
#   2019 Fei Wu

# Run VTLN. This will be run if the vtln option 
# is set to be true in run.sh.

set -eu
stage=0
featdir=mfcc/vtln
data=data
mdl=exp/tri3
mdl_vtln=${mdl}_vtln
vtln_lda=exp/tri4
vtln_sat=exp/tri5
lang_dir=data/lang_test4gr
. ./cmd.sh
. ./utils/parse_options.sh

mkdir -p $featdir

#steps/train_lvtln.sh --cmd "$train_cmd" 1800 9000 $data/train $data/lang $mdl $mdl_vtln

if [ $stage -le 0 ]; then
    mkdir -p $data/train_vtln
    cp $data/train/* $data/train_vtln || true
    cp $mdl_vtln/final.warp $data/train_vtln/spk2warp
    steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" $data/train_vtln exp/make_mfcc/train_vtln $featdir  
    steps/compute_cmvn_stats.sh $data/train_vtln exp/make_mfcc/train_vtln $featdir  
fi

if [ $stage -le 1 ]; then 
    utils/mkgraph.sh $lang_dir $mdl_vtln $mdl_vtln/graph
    steps/decode_lvtln.sh --config conf/decode.config --nj 20 --cmd "$decode_cmd" \
        $mdl_vtln/graph $data/dev $mdl_vtln/decode
fi 

if [ $stage -le 2 ]; then
    mkdir -p $data/dev_vtln
    cp $data/dev/* $data/dev_vtln || true
    cp $mdl_vtln/decode/final.warp $data/dev_vtln/spk2warp
    steps/make_mfcc.sh --nj 8 --cmd "$train_cmd" $data/dev_vtln exp/make_mfcc/dev_vtln $featdir  
    steps/compute_cmvn_stats.sh $data/dev_vtln exp/make_mfcc/dev_vtln $featdir  
fi 

if [ $stage -le 3 ]; then
    steps/train_lda_mllt.sh --cmd "$train_cmd" --splice-opts "--left-context=3 --right-context=3" 1800 9000 \
        $data/train_vtln $data/lang $mdl_vtln $vtln_lda
    utils/mkgraph.sh $lang_dir $vtln_lda $vtln_lda/graph
    echo "$mdl_vtln + lda + mllt" > $vtln_lda/mcodel_discription
    steps/decode.sh --config conf/decode.config --nj 20 --cmd "$decode_cmd" \
        $vtln_lda/graph $data/dev_vtln $vtln_lda/decode
fi

if [ $stage -le 4 ]; then
    steps/train_sat.sh 1800 9000 $data/train_vtln $data/lang $vtln_lda $vtln_sat
    utils/mkgraph.sh $lang_dir $vtln_sat $vtln_sat/graph 
    steps/decode_fmllr.sh --config conf/decode.config --nj 20 --cmd "$decode_cmd" $vtln_sat/graph $data/dev_vtln $vtln_sat/decode 
    echo  "$mdl_vtln + lda + mllt + SAT" > $vtln_sat/model_discription
fi
