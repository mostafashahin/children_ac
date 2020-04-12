# get_wavscp_utt2spk_text.sh
# Author: Renee Lu
# About: This code creates wav.scp and utt2spk files for the CU 2 Kids Speech Corpus
#        Also creates the files needed to prepare text
# Output: For each in train , dev and test:
#         wav.scp
#         utt2spk
#         text
#         transcript

# Output directories
set -e

OUT_DIR=data

# Output files

for data in train dev test; do

  mkdir -p $OUT_DIR/${data}_cu

  for file in wav.scp utt2spk text transcript; do

    [ -f $OUT_DIR/${data}_cu/$file ] && rm $OUT_DIR/${data}_cu/$file

    touch $OUT_DIR/${data}_cu/$file

  done

done

# Required input files
allinfo=$1
train_spkrs=local/spkrs_train.txt
test_spkrs=local/spkrs_test.txt
dev_spkrs=local/spkrs_dev.txt

for data in train dev test; do
   grep -f local/cu_${data}_spkrs $allinfo | cut -d' ' -f1,4 --output-delimiter '-' > $OUT_DIR/${data}_cu/uttid.txt
   grep -f local/cu_${data}_spkrs $allinfo | cut -d' ' -f2  | paste $OUT_DIR/${data}_cu/uttid.txt - > $OUT_DIR/${data}_cu/wav.scp
   grep -f local/cu_${data}_spkrs $allinfo | cut -d' ' -f1  | paste $OUT_DIR/${data}_cu/uttid.txt - > $OUT_DIR/${data}_cu/utt2spk
   cp $OUT_DIR/${data}_cu/uttid.txt $OUT_DIR/${data}_cu/text
   grep -f local/cu_${data}_spkrs $allinfo | cut -d' ' -f3 | xargs cat > $OUT_DIR/${data}_cu/transcript
done
