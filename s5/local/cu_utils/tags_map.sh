# tags_map.sh
# Author: Renee Lu
# About: This code maps the tags in CU 2 Kids Corpus to the common tags
#        as specified in the pre-made file tags_map.txt
# Output: train_transcript_fixed_tags.txt
#         dev_transcript_fixed_tags.txt
#         test_transcript_fixed_tags.txt

LOCAL_OUT=$1
# Required text file (this file should already exist. Else, you can create it yourself)
tags=$LOCAL_OUT/tags_map.txt
[ -f "$tags" ] || echo "ERROR: $tags does not exist. Please add in the file, or create it yourself."

# Iterate through each file, apply fixes and output to the output files
# The required files are created in trans_fixes.sh
for dir in train_cu dev_cu test_cu; do
        old_file=$LOCAL_OUT/tmp/${dir}_transcript_fixed.txt
        file=$LOCAL_OUT/tmp/${dir}_transcript_fixed_tags.txt
        cp $old_file $file
        while IFS= read -r line
        do
                find=$(cut -d ' ' -f1 <<< $line)
                replace=$(cut -d ' ' -f2- <<< $line)
                escaped_find=$(printf '%s\n' "$find" | sed 's:[][\/.^$*]:\\&:g')
                escaped_replace=$(printf '%s\n' "$replace" | sed 's:[][\/.^$*]:\\&:g')
                echo "Replacing $find with $replace for $dir transcript..."             
                sed -i "s/$escaped_find/$escaped_replace/g" "$file"
        done < "$tags"
done
