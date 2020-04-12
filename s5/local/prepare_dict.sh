#!/bin/sh

# Copyright (c) 2018, Johns Hopkins University (Jan "Yenda" Trmal<jtrmal@gmail.com>)
#               2020, FBK 
# License: Apache 2.0

. ./path.sh

dir=data/local/dict
cmudict=cmudict
tlt_lm_train=${tlt_data_dir}/texts/TLT16W17train.trn.txt 
ogi_lm_train=$ogi_data_dir/docs/ogi_lm_train
myst_lm_train=$myst_data_dir/doc/lm_txt/MySTtrain.txt
cmu_lm_train=$cmu_data_dir/cmu_lm_train.txt
cu_lm_train=$cu_data_dir/cu_lm_train.txt
datasets="ogi tlt-9 tlt-40 myst cmu cu"

silence_phones=local/silence_phonemes.txt
silence_lexicon=local/silence_phonemes_lexicon.txt

. ./utils/parse_options.sh

if ! test -d ${dir} ; then mkdir -p $dir ; fi


# silence phones, one per line.
#unk_f for any non-english language
cat $silence_phones | while read w; do
  echo $w;
done > $dir/silence_phones.txt
echo sil > $dir/optional_silence.txt

if [ ! -f $cmudict/cmudict-0.7b ]; then
    echo "Downloading and preparing CMUdict"
    svn co https://svn.code.sf.net/p/cmusphinx/code/trunk/cmudict $cmudict || exit 1;
fi

cat $cmudict/cmudict-0.7b.symbols \
| sed s/[0-9]//g | tr '[A-Z]' '[a-z]' | perl -ane 's:\r::; print;' \
| sort -u > $dir/nonsilence_phones.txt

# An extra question will be added by including the silence phones in one class.
paste -d ' ' -s $dir/silence_phones.txt > $dir/extra_questions.txt

grep -v ';;;' $cmudict/cmudict-0.7b \
| iconv -f latin1 -t utf-8 - |  tr '[A-Z]' '[a-z]' | \
 perl -ane 'if(!m:^;;;:){ s:(\S+)\(\d+\) :$1 :; s:  : :; print; }' | \
 perl -ane '@A = split(" ", $_); for ($n = 1; $n<@A;$n++) { $A[$n] =~ s/[0-9]//g; } print join(" ", @A) . "\n";' \
| sort -u | awk '{printf("%s\t",$1); for (i=2;i<NF;i++) printf("%s ",$i); printf("%s\n",$NF);}' >$dir/iv_lexicon.txt 

for w in `grep -v sil $dir/silence_phones.txt`; do
  echo "@$w $w"
done >> $dir/iv_lexicon.txt
cat $silence_lexicon >> $dir/iv_lexicon.txt

#Accumelate the datasets texts for LM
for dataset in $datasets; do
   if [ "$dataset" == "ogi" ]; then
      lm_train+=" $ogi_lm_train"
   elif [ "$dataset" == "tlt-9" ] || [ "$dataset" == "tlt-40" ]; then
      lm_train+=" $tlt_lm_train"
   elif [ "$dataset" == "myst" ]; then
      lm_train+=" $myst_lm_train"
   elif [ "$dataset" == "cmu" ]; then
      lm_train+=" $cmu_lm_train"
   elif [ "$dataset" == "cu" ]; then 
      lm_train+=" $cu_lm_train"
   fi
done

cat ${lm_train} | \
awk '{for (n=1;n<=NF;n++){ count[$n]++; } } END { for(n in count) { print count[n], n; }}' | \
sort -nr > $dir/word_counts

cat $dir/word_counts | awk '{print $2}' > $dir/word_list

awk '{print $1}' $dir/iv_lexicon.txt | \
  perl -e '($word_counts)=@ARGV;
   open(W, "<$word_counts")||die "opening word-counts $word_counts";
   while(<STDIN>) { chop; $seen{$_}=1; }
   while(<W>) {
     ($c,$w) = split;
     if (!defined $seen{$w}) { print; }
   } ' $dir/word_counts > $dir/oov_counts.txt

echo "*Highest-count OOVs (including fragments) are:"
head -n 10 $dir/oov_counts.txt
echo "*Highest-count OOVs (excluding fragments) are:"
grep -v -E '^-|-$' $dir/oov_counts.txt | head -n 10 || true

echo "*Training a G2P and generating missing pronunciations"
mkdir -p $dir/g2p/
phonetisaurus-align --input=${dir}/iv_lexicon.txt --ofile=$dir/g2p/aligned_lexicon.corpus
ngram-count -order 4 -kn-modify-counts-at-end -ukndiscount\
  -gt1min 0 -gt2min 0 -gt3min 0 -gt4min 0 \
  -text $dir/g2p/aligned_lexicon.corpus -lm $dir/g2p/aligned_lexicon.arpa
phonetisaurus-arpa2wfst --lm=$dir/g2p/aligned_lexicon.arpa --ofile=$dir/g2p/g2p.fst
awk '{print $2}' $dir/oov_counts.txt > $dir/oov_words.txt
phonetisaurus-apply --nbest 2 --model $dir/g2p/g2p.fst --thresh 1 --accumulate \
  --word_list $dir/oov_words.txt > $dir/oov_lexicon.txt

## The next section is again just for debug purposes
## to show words for which the G2P failed
cat $dir/oov_lexicon.txt $dir/iv_lexicon.txt | sort -u > $dir/lexicon.txt
rm -f $dir/lexiconp.txt 2>/dev/null; # can confuse later script if this exists.
awk '{print $1}' $dir/lexicon.txt | \
  perl -e '($word_counts)=@ARGV;
   open(W, "<$word_counts")||die "opening word-counts $word_counts";
   while(<STDIN>) { chop; $seen{$_}=1; }
   while(<W>) {
     ($c,$w) = split;
     if (!defined $seen{$w}) { print; }
   } ' $dir/word_counts > $dir/oov_counts.g2p.txt

echo "*Highest-count OOVs (including fragments) after G2P are:"
head -n 10 $dir/oov_counts.g2p.txt


utils/validate_dict_dir.pl $dir
