# create_text.sh
# Author: Renee Lu
# About: This code creates the file text for kaldi data prep
# Output: For each train, dev, test dir:
#         text 

LOCAL_OUT=$1

# Paste the utterance ids with transcription to create text
# If the required files {dir}_transcript_fixed_tags_lower.txt are not there, they are created in trans2lower.sh
for dir in train_cu dev_cu test_cu; do
	echo "Creating text for $dir ..."
	#mv $DATA_OUT/$dir/text $DATA_OUT/$dir/utt_id
        paste -d ' ' data/$dir/uttid.txt $LOCAL_OUT/${dir}_transcript_fixed_tags_lower.txt > data/$dir/text
done
