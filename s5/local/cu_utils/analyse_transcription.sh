# analyse_text.sh
# Author: Renee Lu
# About: This code analyses the text in the transcriptions of CU 2 Kids Speech Corpus
# Output: tags.txt
#         uniqchars.txt
#         uniqwords_count.txt
#         uniqwords.txt
#         uniqwords_punct.txt
#         transcript_unix.txt
#         transcript_unix_all.txt
#         text.txt
# Output directories
LOCAL_OUTPUT=$1
DATA_OUT=data

mkdir -p $LOCAL_OUTPUT

# Output files
unixall=$LOCAL_OUTPUT/transcript_unix_all.txt
touch $unixall
uniqwords=$LOCAL_OUTPUT/uniqwords.txt
uniqwordscount=$LOCAL_OUTPUT/uniqwords_count.txt
uniqwordspunct=$LOCAL_OUTPUT/uniqwords_punct.txt
uniqchars=$LOCAL_OUTPUT/uniqchars.txt
tags=$LOCAL_OUTPUT/tags.txt

# Convert original transcription to unix
echo "Converting transcription to unix..."
for dir in train_cu dev_cu test_cu; do
	dos2unix -q -n $DATA_OUT/$dir/transcript $LOCAL_OUTPUT/${dir}_transcript_unix.txt
done

# Get all the transcripts in one place
for dir in train_cu dev_cu test_cu; do
	cat $LOCAL_OUTPUT/${dir}_transcript_unix.txt >> $unixall
done

# Get all the unique words, sorted by usage
echo "Listing all unique words and their occurrences in transcription to $uniqwordscount ..."
cat $unixall | sed -r 's/[[:space:]]+/\n/g' | sed '/^$/d' | sort | uniq -c | sort -n > $uniqwordscount

# Get all the unique words
echo "Listing all unique words to $uniqwords ..."
cat $unixall | sed -r 's/[[:space:]]+/\n/g' | sed '/^$/d' | sort -u > $uniqwords

# Get all the unique characters
echo "Listing all the unique characters in transcription to $uniqchars ..."
grep -o . $unixall | sort -u > $uniqchars

# Get only the lowercase words (i.e. tags)
echo "Listing all the tags in transcription to $tags ..."
cat $uniqwords | grep -v '[^[:lower:]]' > $tags

# Get all the words with punctuation
echo "Listing all unique words with punctuation in $uniqwordspunct ..."
sed '/[[:punct:]]/!d' $uniqwords > $uniqwordspunct

# Paste the unix transcription with text file
for dir in train_cu dev_cu test_cu; do
        paste -d ' ' $DATA_OUT/$dir/wav.scp $LOCAL_OUTPUT/${dir}_transcript_unix.txt > $LOCAL_OUTPUT/text_${dir}.txt
done
