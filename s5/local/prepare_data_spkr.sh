data_sp_dir=data/train_sp_hires
dir=exp/nnet3_tdnnf/
ali_dir=exp/tri3_ali_train_sp/
ivect=0
num_utt_per_spkr=10
samples_per_iter=100000
data_dir=data/train_spk_hires_$num_utt_per_spkr
stage=1
model_left_context=42
model_right_context=42

set -e

if [ $stage -le 1 ]; then
    mkdir -p $data_dir || exit 1
 
    cat $data_sp_dir/utt2spk | sed '/^sp/d' | cut -d' ' -f1 > $data_dir/utt_list
    
    utils/subset_data_dir.sh --utt-list $data_dir/utt_list $data_sp_dir data/tmp
    
    utils/subset_data_dir.sh --per-spk data/tmp  $num_utt_per_spkr $data_dir
    
    if [ $ivect -eq 1 ]; then
        ivect_opt="--online-ivector-dir exp/nnet3/ivectors_train_sp_hires/"
    fi
    
   
    steps/nnet3/get_egs.sh --cmd run.pl --cmvn-opts "--norm-means=false --norm-vars=false" $ivect_opt --left-context $model_left_context --right-context $model_right_context --left-context-initial -1 --right-context-final -1 --nj 16 --stage 0 --samples-per-iter $samples_per_iter --frames-per-eg 8 --generate-egs-scp true --srand 0 $data_sp_dir $ali_dir $dir/egs_sp_with_scp
    
    steps/nnet3/get_egs.sh --cmd run.pl --cmvn-opts "--norm-means=false --norm-vars=false" $ivect_opt --left-context $model_left_context --right-context $model_right_context --left-context-initial -1 --right-context-final -1 --nj 16 --stage 0 --samples-per-iter $samples_per_iter --frames-per-eg 8 --generate-egs-scp true --srand 0 $data_dir $ali_dir $dir/egs_with_scp
    
fi    

i=0
[ -f $data_dir/spk2int ] && rm $data_dir/spk2int
for spk in $(cat $data_dir/spk2utt | cut -d' ' -f1 | sort -u); do
    echo $spk $i >> $data_dir/spk2int
    i=$((i+1))
done
    
dim=$i

if [ $stage -le 2 ]; then
    [ -d $dir/egs_spk/ ] || mkdir $dir/egs_spk/
    
    for f in $dir/egs_with_scp/*.egs; do
        ../../../src/nnet3bin/nnet3-copy-egs ark:$f ark,t:- |./local/convert_to_spkr.py $data_dir/spk2int $data_dir/utt2spk $dim $ivect |../../../src/nnet3bin/nnet3-copy-egs ark:- ark,scp:$dir/egs_spk/$(basename $f),$dir/egs_spk/$(basename $f .egs).scp &
     done
    
    wait;
    
    for f in $dir/egs_with_scp/egs.*.ark; do 
        ../../../src/nnet3bin/nnet3-copy-egs ark:$f ark,t:- | ./local/convert_to_spkr.py $data_dir/spk2int $data_dir/utt2spk $dim $ivect | ../../../src/nnet3bin/nnet3-copy-egs ark:- ark,scp:$dir/egs_spk/$(basename $f),$dir/egs_spk/$(basename $f .ark).scp &
    done
    
    wait;
fi
    
cat $dir/egs_spk/egs.*.scp > $dir/egs_spk/egs.scp

mkdir -p $dir/egs_comb_spk/

steps/nnet3/multilingual/combine_egs.sh 2 $dir/egs_sp_with_scp $dir/egs_spk $dir/egs_comb_spk
