# cu2_dataprep.sh
# Author: Renee Lu
# About: This prepares the data for the CU2 Kids Speech Corpus
#        To be run from s5 directory

# So that the sorting is correct
set -e
. ./path.sh
[ -z $cu_data_dir ] && ( echo 'Please Define cu_data_dir var in path.sh' && exit )

# Define current directory
ROOT_DIR=$(pwd)

# Define local, local output and data output
UTILS_DIR=local/cu_utils

mkdir -p $UTILS_DIR/tmp

DATA_OUT=data

mkdir -p $DATA_OUT

#Add path to allinfo.txt
cat $UTILS_DIR/allinfo.txt | sed "s,PATH-TO-DATA,$cu_data_dir,g" > $UTILS_DIR/tmp/allinfo.txt

# List all the available audio and transcription files
echo "Listing all the available audio and transcription files..."
#local/diff_audio_text.sh $DATA_DIR $LOCAL_OUT

# Map each file to speaker-id. We do this because different parts in the corpus have different
# naming conventions
echo "Mapping each file to its speaker id..."
#local/file2spk.sh $LOCAL_OUT

# Create allinfo.txt which contains all the information needed to create Kaldi data prep files
echo "Getting ready to create kaldi data preparation files..."
#local/allinfo.sh $LOCAL_OUT

# Get the total list of unique speakers
#local/getspkrs.sh $LOCAL_OUT

# Split the data into training, development and testing 
# Set the data split proportions inside the script
echo "Splitting the data into training, development and test sets..."
#local/split_data.sh $LOCAL_OUT

# Create wav.scp and utt2spk and prep files for text
echo "Creating wav.scp, utt2spk and preparing to create text..."
$UTILS_DIR/get_wavscp_utt2spk_text.sh $UTILS_DIR/tmp/allinfo.txt 

# Analyse the transcript before creating text
echo "Analysing transcript content..."
$UTILS_DIR/analyse_transcription.sh $UTILS_DIR/tmp

# Apply fixes to the transcription e.g. fix human typos
echo "Applying fixes to the transcription..."
$UTILS_DIR/trans_fixes.sh $UTILS_DIR

# Map corpus tags to common tags
echo "Mapping corpus tags to common tags..."
$UTILS_DIR/tags_map.sh $UTILS_DIR

# Create output files to check the fixes to typos and tags are correct
echo "Creating files to check the previous fixes..."
$UTILS_DIR/check_fixes.sh $UTILS_DIR/tmp

# Convert everything to lower case in transcription
echo "Converting all transcription to lowercase..."
$UTILS_DIR/trans2lower.sh $UTILS_DIR/tmp

# Create the kaldi prep file 'text'
echo "Creating text file..."
$UTILS_DIR/create_text.sh $UTILS_DIR/tmp

for data in train_cu test_cu dev_cu; do
    #Sort Files
    sort -o data/$data/text data/$data/text
    sort -o data/$data/utt2spk data/$data/utt2spk
    sort -o data/$data/wav.scp data/$data/wav.scp

    utils/utt2spk_to_spk2utt.pl data/$data/utt2spk > data/$data/spk2utt
    utils/fix_data_dir.sh data/$data

done

#Clean
rm -r $UTILS_DIR/tmp

echo "SUCCESS: Data preparation done."
