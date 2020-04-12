# check_fixes.sh
# Author: Renee Lu
# About: This code checks that the fixes and tags have been implemented properly.
# Output

LOCAL_OUTPUT=$1

# Output files
fixall=$LOCAL_OUTPUT/fix_all.txt
touch $fixall
uniqwords=$LOCAL_OUTPUT/uniqwords_fixed.txt
uniqwordscount=$LOCAL_OUTPUT/uniqwords_count_fixed.txt
uniqwordspunct=$LOCAL_OUTPUT/uniqwords_punct_fixed.txt
uniqchars=$LOCAL_OUTPUT/uniqchar_fixed.txt
tags=$LOCAL_OUTPUT/tags_fixed.txt

# Get all the transcripts in one place
for dir in train_cu dev_cu test_cu; do
        cat $LOCAL_OUTPUT/${dir}_transcript_fixed_tags.txt >> $fixall
done

# Get all the unique words, sorted by usage
echo "Listing all unique words and their occurrences in transcription to $uniqwordscount ..."
cat $fixall | sed -r 's/[[:space:]]+/\n/g' | sed '/^$/d' | sort | uniq -c | sort -n > $uniqwordscount

# Get all the unique words
echo "Listing all unique words to $uniqwords ..."
cat $fixall | sed -r 's/[[:space:]]+/\n/g' | sed '/^$/d' | sort -u > $uniqwords

# Get all the unique characters
echo "Listing all the unique characters in transcription to $uniqchars ..."
grep -o . $fixall | sort -u > $uniqchars

# Get only the lowercase words (i.e. tags)
echo "Listing all the tags in transcription to $tags ..."
cat $uniqwords | grep -v '[^[:lower:]]' > $tags

# Get all the words with punctuation
echo "Listing all unique words with punctuation in $uniqwordspunct ..."
sed '/[[:punct:]]/!d' $uniqwords > $uniqwordspunct
