#!/bin/sh

. ./path.sh

datasets="ogi tlt-9 tlt-40 myst cmu"
#Train LM text
tlt_lm_train=${tlt_data_dir}/texts/TLT16W17train.trn.txt
ogi_lm_train=$ogi_data_dir/docs/ogi_lm_train
myst_lm_train=$myst_data_dir/doc/lm_txt/MySTtrain.txt
cmu_lm_train=$cmu_data_dir/cmu_lm_train.txt
cu_lm_train=$cu_data_dir/cu_lm_train.txt

#Dev LM text
tlt_lm_dev=${tlt_data_dir}/texts/TLT2017dev.trn.txt
ogi_lm_dev=$ogi_data_dir/docs/ogi_lm_dev
myst_lm_dev=$myst_data_dir/doc/lm_txt/MySTdev.txt
cu_lm_dev=$cu_data_dir/cu_lm_dev.txt


#Test LM text
ogi_lm_test=$ogi_data_dir/docs/ogi_lm_test
myst_lm_test=$myst_data_dir/doc/lm_txt/MySTtest.txt
cu_lm_test=$cu_data_dir/cu_lm_test.txt


oov_symbol="<unk>"
suffix=
lm_dir=data/local/srilm
ngr=4
. ./utils/parse_options.sh

if ! test -d ${lm_dir}; then mkdir -p ${lm_dir}; fi
lm=${lm_dir}/${ngr}gram.me.gz

for dataset in $datasets; do
   if [ "$dataset" == "ogi" ]; then
      lm_train+=" $ogi_lm_train"
      lm_dev+=" $ogi_lm_dev"
      lm_test+=" $ogi_lm_test"
   elif [ "$dataset" == "tlt-9" ] || [ "$dataset" == "tlt-40" ]; then
      lm_train+=" $tlt_lm_train"
      lm_dev+=" $tlt_lm_dev"
   elif [ "$dataset" == "myst" ]; then
      lm_train+=" $myst_lm_train"
      lm_dev+=" $myst_lm_dev"
      lm_test+=" $myst_lm_test"
   elif [ "$dataset" == "cmu" ]; then
      lm_train+=" $cmu_lm_train"
   elif [ "$dataset" == "cu" ]; then
      lm_train+=" $cu_lm_train"
      lm_dev+=" $cu_lm_dev"
      lm_test+=" $cu_lm_test"
   fi
done

#cat $lm_train > ${lm_dir}/train_text
echo train lm on $lm_train
cat $lm_train | ngram-count -lm - -order ${ngr} -text - \
	-unk -sort -maxent -maxent-convert-to-arpa|\
    ngram -lm - -order ${ngr} -unk -map-unk "$oov_symbol" -prune-lowprobs -write-lm - |\
    sed 's/<unk>/'${oov_symbol}'/g' | gzip -c > $lm

for lm_text in $lm_dev $lm_test; do

  echo    ngram -order ${ngr} -lm $lm -unk -map-unk "$oov_symbol" -prune-lowprobs -ppl ${lm_text}
  ngram -order ${ngr} -lm $lm -unk -map-unk "$oov_symbol" -prune-lowprobs -ppl ${lm_text}
done

utils/format_lm.sh \
	data/lang $lm data/local/dict/lexicon.txt data/lang_test${ngr}gr$suffix
