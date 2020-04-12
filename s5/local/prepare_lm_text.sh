#Convert data text file to lm text
#Removing the uttID and silence words except specified in keep_symb
keep_symb="<unk> <unk_f>"
extra_oov="<bs> <uu> @voices @voice"
extra_oov_f="<nitl> <unk-it> <unk-de>"
silence_lexicon_file=
. ./utils/parse_options.sh

inFile=$1
outFile=$2
[ -f $inFile ] || (echo "input file $inFile not excist" && exit 1)

if [ ! -z $silence_lexicon_file ]; then
   [ -f $silence_lexicon_file ] || (echo "silence lexicon file $silence_lexicon_file not excist" && exit 1)
   rem_symb=$(echo \(`cat $silence_lexicon_file | cut -d' ' -f1 | grep -vP $(echo $keep_symb | tr ' ' '|') | xargs`\) | tr ' ' '|')
fi
cat $inFile | cut -d' ' -f2- | sed -re "s/$(echo \($extra_oov\) | tr ' ' '|')/<unk>/g" -e "s/$(echo \($extra_oov_f\) | tr ' ' '|')/<unk_f>/g" -e "s/$rem_symb//g" -e 's/ +/ /g' | sort -u > $outFile 
