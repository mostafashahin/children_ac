export KALDI_ROOT=`pwd`/../../..
[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin::$KALDI_ROOT/tools/Phonetisaurus/bin/:$KALDI_ROOT/tools/srilm/bin/i686-m64:$KALDI_ROOT/tools/sph2pipe_v2.5:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "The standard file $KALDI_ROOT/tools/config/common_path.sh is not present -> Exit!" && exit 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C
export tlt_data_dir=/srv/scratch/z5173707/Dataset/TLT/TLT2020challenge
export tlt_data_dir_1618=/srv/scratch/z5173707/Dataset/TLT/TLT2020challenge2P
export ogi_data_dir=/srv/scratch/z5173707/Dataset/OGI/
export myst_data_dir=/srv/scratch/z5173707/Dataset/MyST/
export cmu_data_dir=/srv/scratch/z5173707/Dataset/CMU/cmu_kids/
export cu_data_dir=/srv/scratch/z5173707/Dataset/CU_2/
