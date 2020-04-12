# trans_fixes.sh
# Author: Renee Lu
# About: This code uses the pre-made trans_fixes.txt file to fix human typos
#        in the CU 2 Kids Speech Corpus transcription.
# Output: train_transcript_fixed.txt
#         dev_transcript_fixed.txt
#         test_transcript_fixed.txt

LOCAL_OUT=$1

# Required text file (this file should already exist. Else, you can create it yourself)
fixes=$LOCAL_OUT/trans_fixes.txt
[ -f "$fixes" ] || echo "ERROR: $fixes does not exist. Please add in the file, or create it yourself."

# Iterate through each file, apply fixes and output to the output files
# The required files are created in analyse_text.sh
for dir in train_cu dev_cu test_cu; do
        old_file=$LOCAL_OUT/tmp/${dir}_transcript_unix.txt
	file=$LOCAL_OUT/tmp/${dir}_transcript_fixed.txt
	cp $old_file $file
	while IFS= read -r line
	do
		find=$(cut -d ' ' -f1 <<< $line)
		replace=$(cut -d ' ' -f2- <<< $line)
		escaped_find=$(printf '%s\n' "$find" | sed 's:[][\/.^$*]:\\&:g')
		escaped_replace=$(printf '%s\n' "$replace" | sed 's:[][\/.^$*]:\\&:g')
		echo "Replacing $find with $replace for $dir transcript..."		
		sed -i "s/$escaped_find/$escaped_replace/g" "$file"
	done < "$fixes"
done 
