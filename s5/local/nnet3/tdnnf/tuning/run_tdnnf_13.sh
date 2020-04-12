#!/bin/bash

# d is as c, but with one extra layer.

# At this script level we don't support not running on GPU, as it would be painfully slow.
# If you want to run without GPU you'd have to call train_tdnn.sh with --gpu false,
# --num-threads 16 and --minibatch-size 128.

# note: the last column is a version of tdnn_d that was done after the
# changes for the 5.1 version of Kaldi (variable minibatch-sizes, etc.)

stage=9
affix=
train_stage=-10
has_fisher=false
speed_perturb=true
common_egs_dir=
reporting_email=
remove_egs=false
num_jobs=16

. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh


if ! cuda-compiled; then
  cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
fi

suffix=
if [ "$speed_perturb" == "true" ]; then
  suffix=_sp
fi
dir=exp/nnet3_tdnnf/tdnn_13
dir=$dir${affix:+_$affix}
dir=${dir}$suffix
train_set=train
ali_dir=exp/tri3_ali_train_sp/
if [ $stage -le 1 ]; then
  local/nnet3/run_sp_hires.sh --stage $stage --speed-perturb $speed_perturb --num-jobs $num_jobs || exit 1
fi
dropout_schedule='0,0@0.20,0.5@0.50,0'
if [ $stage -le 9 ]; then
  echo "$0: creating neural net configs using the xconfig parser";

  num_targets=$(tree-info $ali_dir/tree | grep num-pdfs | awk '{print $2}')
  linear_opts="l2-regularize=0.008 orthonormal-constraint=-1.0"
  tdnn_opts="l2-regularize=0.008 dropout-proportion=0.0 dropout-per-dim-continuous=true"
  tdnnf_opts="l2-regularize=0.008 dropout-proportion=0.0 bypass-scale=0.66"
  prefinal_opts="l2-regularize=0.002"

mkdir -p $dir/configs
  cat <<EOF > $dir/configs/network.xconfig
  input dim=100 name=ivector
  input dim=40 name=input

  idct-layer name=idct input=input dim=40 cepstral-lifter=22 affine-transform-file=$dir/configs/idct.mat
  delta-layer name=delta input=idct
  no-op-component name=input2 input=Append(-1,0,1, Scale(1.0, ReplaceIndex(ivector, t, 0)))

  # the first splicing is moved before the lda layer, so no splicing here
  relu-batchnorm-layer name=tdnn1 $tdnn_opts dim=1536 input=input2
  tdnnf-layer name=tdnnf2 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
  tdnnf-layer name=tdnnf3 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
  tdnnf-layer name=tdnnf4 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=1
  tdnnf-layer name=tdnnf5 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=0
  tdnnf-layer name=tdnnf6 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf7 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf8 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf9 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf10 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf11 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf12 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf13 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf14 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf15 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf16 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  tdnnf-layer name=tdnnf17 $tdnnf_opts dim=1536 bottleneck-dim=160 time-stride=3
  linear-component name=prefinal-l dim=256 $linear_opts

  prefinal-layer name=prefinal input=prefinal-l $prefinal_opts big-dim=1536 small-dim=256
  output-layer name=output input=prefinal dim=$num_targets max-change=1.5
EOF

steps/nnet3/xconfig_to_configs.py --xconfig-file $dir/configs/network.xconfig --config-dir $dir/configs/
fi

if [ $stage -le 10 ]; then
#--trainer.samples-per-iter 5000000 
  steps/nnet3/train_dnn.py --stage=$train_stage \
    --cmd="$decode_cmd" \
    --feat.online-ivector-dir exp/nnet3/ivectors_${train_set}_sp_hires/ \
    --feat.cmvn-opts="--norm-means=false --norm-vars=false" \
    --trainer.num-epochs 4 \
    --trainer.dropout-schedule $dropout_schedule \
    --trainer.optimization.num-jobs-initial 2 \
    --trainer.optimization.num-jobs-final 2 \
    --trainer.optimization.initial-effective-lrate 0.00015 \
    --trainer.optimization.final-effective-lrate 0.000015 \
    --trainer.optimization.do-final-combination true \
    --egs.dir "$common_egs_dir" \
    --cleanup.remove-egs $remove_egs \
    --cleanup.preserve-model-interval 100 \
    --use-gpu wait \
    --feat-dir=data/${train_set}${suffix}_hires \
    --ali-dir $ali_dir \
    --lang data/lang \
    --reporting.email="$reporting_email" \
    --dir=$dir  || exit 1;

fi
graph_dir=exp/tri3_ali_train_sp/graph
if [ $stage -le 11 ]; then
  # The reason we are using data/lang here, instead of $lang, is just to
  # emphasize that it's not actually important to give mkgraph.sh the
  # lang directory with the matched topology (since it gets the
  # topology file from the model).  So you could give it a different
  # lang directory, one that contained a wordlist and LM of your choice,
  # as long as phones.txt was compatible.

  utils/lang/check_phones_compatible.sh \
    data/lang_test4gr/phones.txt data/lang/phones.txt

  utils/mkgraph.sh data/lang_test4gr ${ali_dir} ${graph_dir} || exit 1;

fi

if [ $stage -le 12 ]; then
  for decode_set in dev ; do
    (
    num_jobs=`cat data/${decode_set}_hires/utt2spk|cut -d' ' -f2|sort -u|wc -l`
    steps/nnet3/decode.sh --nj 16 --cmd "$decode_cmd" \
      --skip_diagnostics true \
      --online-ivector-dir exp/nnet3/ivectors_${decode_set}_hires/ \
      $graph_dir data/${decode_set}_hires $dir/decode_${decode_set}_hires || exit 1;
    ) &
  done
fi

wait;
exit 0
