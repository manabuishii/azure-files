#!/bin/bash

#cd /data

if [ ! -e "adapter_primer" ]; then
  curl https://q-brain2.riken.jp/bayes/data/adapter_primer_20160210.tar.gz | tar zxvf -
fi
if [ ! -e "transcriptome_ref_fasta" ]; then
  curl https://q-brain2.riken.jp/bayes/data/transcriptome_ref_fasta_20160210.tar.gz | tar zxvf -
fi
if [ ! -e "quartz_div100_rename" ]; then
  curl https://q-brain2.riken.jp/bayes/data/quartz_div100_rename_20160210.tar.gz | tar zxvf -
fi
if [ ! -e "bowtie2_index" ]; then
  curl https://q-brain2.riken.jp/bayes/data/bowtie2_index_20160210.tar.gz | tar zxvf -
fi
if [ ! -e "sailfish_index" ]; then
  curl https://q-brain2.riken.jp/bayes/data/sailfish_index_20160210.tar.gz | tar zxvf -
fi
if [ ! -e "sailfish_0.9_index" ]; then
  curl https://q-brain2.riken.jp/bayes/data/sailfish_0.9_index_20161202.tar.gz | tar zxvf -
fi
