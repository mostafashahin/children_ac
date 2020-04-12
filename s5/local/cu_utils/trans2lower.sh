# trans2lower.sh
# Author: Renee Lu
# About: This converts the transcription to lower case
# Output: train_transcript_fixed_tags_lower.txt
#         test_transcript_fixed_tags_lower.txt
#         dev_transcript_fixed_tags_lower.txt

LOCAL_OUT=$1

# If the required files of {train/dev/test}_transcript_fixed_tags.txt are not there
# It can be created by tags_map.sh
for dir in train_cu dev_cu test_cu; do
	infile=$LOCAL_OUT/${dir}_transcript_fixed_tags.txt
	outfile=$LOCAL_OUT/${dir}_transcript_fixed_tags_lower.txt
	sed 's/.*/\L&/g' $infile > $outfile  
done
