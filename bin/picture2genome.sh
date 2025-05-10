#!/usr/bin/bash
#Description: convert loop from picture.
#Usage:sh picture2genome.sh dir
#Author: zhanglp
#Date: 20241218

dir=$1
# Check and remove tmp_loop.bedpe if it exists
if [ -f "tmp_loop.bedpe" ]; then
    rm -f "tmp_loop.bedpe"
fi

ls $dir | while read name;
do
chr=`echo $name | cut -d "_" -f 1`
start=`echo $name | cut -d "_" -f 2`
#let end=$start+20000
awk '$1>0.6{print int($2/800*20000),int($3/800*20000),int($4/800*20000),int($5/800*20000)}' ${dir}/${name} | awk -v chr=$chr -v s=$start 'BEGIN{OFS="\t"}{print chr,$2+s,$4+s,chr,$1+s,$3+s}' >> tmp_loop.bedpe
done

pgltools formatbedpe tmp_loop.bedpe | pgltools sort - | pgltools merge -stdInA | grep -v "#" > loop.bedpe
