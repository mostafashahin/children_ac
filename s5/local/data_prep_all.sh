#!/bin/bash

# Copyright (c) 2020, UNSW 
# License: Apache 2.0

set -e
. ./path.sh
#ogi_data_dir=/srv/scratch/z5173707/Dataset/OGI/   #Should contain doc directory
#tlt_data_dir=/srv/scratch/z5173707/Dataset/TLT/TLT2020challenge/  #9 hours
#tlt_data_dir_1618=/srv/scratch/z5173707/Dataset/TLT/TLT2020challenge2P/ #40 hours
#myst_data_dir=/srv/scratch/z5173707/Dataset/MyST/

datasets="ogi tlt-9 tlt-40 myst cmu cu"

. ./utils/parse_options.sh 

echo $datasets
for d in $datasets; do
  if [ "$d" == "ogi" ]; then
    if [ ! -z $ogi_data_dir ]; then
      if [ ! -d data/train_$d ]; then
        #You can select either spontenous or read data by set the --data-prep-opt to "-r -s", "-r" or "-s"
        ./local/ogi_data_prep.sh --ogi-data-dir $ogi_data_dir
        combine_str+=" data/train_$d"
      else
        echo "ogi train data dir exist, delet it if you mean to reprepare dataset"
      fi
    else
       echo "Please set the ogi_data_dir var in path.sh"
       exit 1
    fi
  
  elif [ "$d" == "tlt-9" ]; then
    if [ ! -z $tlt_data_dir ]; then
      if [ ! -d data/train_$d ]; then
        ./local/tlt-9_data_prep.sh --tlt-data-dir $tlt_data_dir
        combine_str+=" data/train_$d"
      else
        echo "tlt-9 train data dir exist, delet it if you mean to reprepare dataset"
      fi
    else
       echo "Please set the tlt_data_dir var in path.sh"
       exit 1
    fi

  elif [ "$d" == "tlt-40" ]; then
    if [ ! -z $tlt_data_dir_1618 ]; then
      if [ ! -d data/train_$d ]; then
        ./local/tlt-40_data_prep.sh --tlt-data-dir $tlt_data_dir_1618
        combine_str+=" data/train_$d"
      else
        echo "tlt-40 train data dir exist, delet it if you mean to reprepare dataset"
      fi
     else
       echo "Please set the tlt_data_dir_1618 var in path.sh"
       exit 1
    fi
 
  elif [ "$d" == "myst" ]; then
    if [ ! -z $myst_data_dir ]; then
      if [ ! -d data/train_$d ]; then
        ./local/myst_data_prep.sh --myst-data-dir $myst_data_dir
        combine_str+=" data/train_$d"
      else
        echo "myst train data dir exist, delet it if you mean to reprepare dataset"
      fi
    else
      echo "Please set the myst_data_dir var in path.sh"
      exit 1
    fi
  elif [ "$d" == "cmu" ]; then 
    if [ ! -z $cmu_data_dir ]; then
      if [ ! -d data/train_$d ]; then
        ./local/cmu_kids_data_prep.sh --cmu-data-dir /srv/scratch/z5173707/Dataset/CMU/cmu_kids/
        combine_str+=" data/train_$d"
      else
        echo "cmu train data dir exist, delet it if you mean to reprepare dataset"
      fi
    else
      echo "Please set the cmu_data_dir var in path.sh"
      exit 1
    fi
  fi
  elif [ "$d" == "cu" ]; then
    if [ ! -z $cu_data_dir ]; then
      if [ ! -d data/train_$d ]; then
        #You can select either spontenous or read data by set the --data-prep-opt to "-r -s", "-r" or "-s"
        ./local/cu_data_prep.sh
        combine_str+=" data/train_$d"
      else
        echo "cu train data dir exist, delet it if you mean to reprepare dataset"
      fi
    else
       echo "Please set the cu_data_dir var in path.sh"
       exit 1
    fi
done
#Combine all training data
./utils/combine_data.sh data/train $combine_str
