#!/usr/bin/bash
#Description: Count the contacts with slide window.
#Usage:sh slide_plot.sh BraA02g027790 
#Author: zhanglp
#Date: 20240624

chr=$1
start=$2
end=$3
window=$4
step=$5
ID=${chr}_${start}
input=${6}${chr}.bedpe
out=$7

awk -v start=$start -v end=$end '{if($2>start&&$5<end)print $1,$2,$3,$4,$5,$6,$7}' $input > ${out}${ID}_raw.txt
awk -v step=$step -v bin=$window -v start=$start -v end=$end 'BEGIN{for(i=start;i<end;i+=step)print i"\t"i+bin}' | awk '{print $0"\t"NR}' > $out${ID}_bin_step.bed
awk 'ARGIND==1{dic[$3][1]=$1;dic[$3][2]=$2}ARGIND==2{for(peak in dic){if($2>dic[peak][1]&&$2<dic[peak][2])print $7,$2,peak}}' $out${ID}_bin_step.bed $out${ID}_raw.txt > $out${ID}_anchor1.txt
awk 'ARGIND==1{dic[$3][1]=$1;dic[$3][2]=$2}ARGIND==2{for(peak in dic){if($5>dic[peak][1]&&$5<dic[peak][2])print $7,$5,peak}}' $out${ID}_bin_step.bed $out${ID}_raw.txt > $out${ID}_anchor2.txt
awk 'ARGIND==1{fdic[$1][NR]=$3}ARGIND==2{sdic[$1][NR]=$3}END{for(id in fdic){for(peak1 in fdic[id]){for(peak2 in sdic[id])print id,fdic[id][peak1],sdic[id][peak2]}}}' $out${ID}_anchor1.txt $out${ID}_anchor2.txt | awk '{dic[$2][$3]++}END{for(i in dic)for(j in dic[i])print i,j,dic[i][j]}' | sort -k 1,1n -k 2,2n | awk 'BEGIN{OFS="\t"}$1<=$2{print $1,$2,$3}' > $out${ID}_long.txt
rm $out${ID}_raw.txt $out${ID}_bin_step.bed $out${ID}_anchor1.txt $out${ID}_anchor2.txt 
