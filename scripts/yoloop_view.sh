#!/bin/bash

# 默认参数值
MODE="class"
BIN_SIZE=100
WINDOW_SIZE=300
STEP=10

# 显示帮助信息
usage() {
    echo "Usage: $0 -i <interaction_dir> -c <chromosome> -s <start_coord> -e <end_coord> [-m <mode>] [-b <bin_size>] [-w <window_size>] [-t <step>] [-x <background_file>]"
    echo "Required parameters:"
    echo "  -i  Interaction file directory"
    echo "  -c  Chromosome"
    echo "  -s  Start coordinate"
    echo "  -e  End coordinate"
    echo "Optional parameters:"
    echo "  -m  Plot mode (class|gussian|correct) [default: $MODE]"
    echo "  -b  Bin size (for class mode) [default: $BIN_SIZE]"
    echo "  -w  Window size (for gaussian/correct mode) [default: $WINDOW_SIZE]"
    echo "  -t  Step size (for gaussian/correct mode) [default: $STEP]"
    echo "  -x  Background file (required for correct mode)"
    exit 1
}

# 解析命令行参数
while getopts ":i:c:s:e:m:b:w:t:x:" opt; do
    case $opt in
        i) INTERACTION_DIR=$OPTARG ;;
        c) CHROMOSOME=$OPTARG ;;
        s) START_COORD=$OPTARG ;;
        e) END_COORD=$OPTARG ;;
        m) MODE=$OPTARG ;;
        b) BIN_SIZE=$OPTARG ;;
        w) WINDOW_SIZE=$OPTARG ;;
        t) STEP=$OPTARG ;;
        x) BACKGROUND=$OPTARG ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# 检查必需参数是否提供
if [ -z "$INTERACTION_DIR" ] || [ -z "$CHROMOSOME" ] || [ -z "$START_COORD" ] || [ -z "$END_COORD" ]; then
    echo "Error: Missing required parameters." >&2
    usage
fi

# 检查模式是否有效
case "$MODE" in
    class|gaussian|correct) ;;
    *) echo "Error: Invalid mode '$MODE'. Must be one of: class, gussian, correct" >&2; usage ;;
esac

# 根据模式设置默认参数
if [ "$MODE" == "class" ]; then
    echo "Using classical mode with bin size $BIN_SIZE"
elif [ "$MODE" == "gaussian" ]; then
    echo "Using $MODE mode with window size $WINDOW_SIZE and step size $STEP"
else
    echo "Using $MODE mode with window size $WINDOW_SIZE and step size $STEP"
    echo "Using $MODE mode with background file $BACKGROUND"
fi

# 伪代码：转换Hi-C矩阵为H5
echo "Converting Hi-C matrix to h5 format..."
echo "Parameters:"
echo "  Interaction directory: $INTERACTION_DIR"
echo "  Chromosome: $CHROMOSOME"
echo "  Region: ${START_COORD}-${END_COORD}"
echo "  Mode: $MODE"

if [ "$MODE" == "class" ]; then
    echo "  Bin size: $BIN_SIZE"
    awk -v start=$START_COORD -v end=$END_COORD '{if($2>start&&$5<end)print $1,$2,$3,$4,$5,$6,$7}' $INTERACTION_DIR"/"$CHROMOSOME".bedpe" > ${CHROMOSOME}_${START_COORD}_raw.txt
    awk -v bin=$BIN_SIZE -v start=$START_COORD -v end=$END_COORD -v chr=$CHROMOSOME 'BEGIN{OFS="\t";for(i=start;i<end;i+=bin)print chr,i,i+bin,int((i-start)/100)+1}' > ${CHROMOSOME}_${START_COORD}_abs.bed
    awk -v bin=$BIN_SIZE -v start=$START_COORD 'BEGIN{OFS="\t"}{print int(($2-start)/bin)+1,int(($5-start)/bin)+1}' ${CHROMOSOME}_${START_COORD}_raw.txt | awk '{dic[$1][$2]++}END{for(i in dic)for(j in dic[i])print i,j,dic[i][j]}' | sort -k 1,1n -k 2,2n | awk 'BEGIN{OFS="\t"}$1<=$2{print $1,$2,$3}' > ${CHROMOSOME}_${START_COORD}_long.txt
    hicConvertFormat -m ${CHROMOSOME}_${START_COORD}_long.txt --bedFileHicpro ${CHROMOSOME}_${START_COORD}_abs.bed --inputFormat hicpro --outputFormat h5 -o ${CHROMOSOME}_${START_COORD}_class_matrix.h5
    hicPlotMatrix -m ${CHROMOSOME}_${START_COORD}_class_matrix.h5 -o ${CHROMOSOME}_${START_COORD}_class_matrix.png
    rm ${CHROMOSOME}_${START_COORD}_raw.txt ${CHROMOSOME}_${START_COORD}_abs.bed ${CHROMOSOME}_${START_COORD}_long.txt 

elif [ "$MODE" == "gaussian" ];then
    echo "  Window size: $WINDOW_SIZE"
    echo "  Step: $STEP"
    awk -v start=$START_COORD -v end=$END_COORD '{if($2>start&&$5<end)print $1,$2,$3,$4,$5,$6,$7}' $INTERACTION_DIR"/"$CHROMOSOME".bedpe" > ${CHROMOSOME}_${START_COORD}_raw.txt
    awk -v step=$STEP -v window=$WINDOW_SIZE -v start=$START_COORD -v end=$END_COORD 'BEGIN{for(i=start;i<end;i+=step)print i"\t"i+window}' | awk '{print $0"\t"NR}' > ${CHROMOSOME}_${START_COORD}_bin_step.bed
    awk -v chr=$CHROMOSOME -v step=$STEP 'BEGIN{OFS="\t"}{print chr,$1,$1+step,$3}' ${CHROMOSOME}_${START_COORD}_bin_step.bed > ${CHROMOSOME}_${START_COORD}_abs.bed
    awk 'ARGIND==1{dic[$3][1]=$1;dic[$3][2]=$2}ARGIND==2{for(peak in dic){if($2>dic[peak][1]&&$2<dic[peak][2])print $7,$2,peak}}' ${CHROMOSOME}_${START_COORD}_bin_step.bed ${CHROMOSOME}_${START_COORD}_raw.txt > ${CHROMOSOME}_${START_COORD}_anchor1.txt
    awk 'ARGIND==1{dic[$3][1]=$1;dic[$3][2]=$2}ARGIND==2{for(peak in dic){if($5>dic[peak][1]&&$5<dic[peak][2])print $7,$5,peak}}' ${CHROMOSOME}_${START_COORD}_bin_step.bed ${CHROMOSOME}_${START_COORD}_raw.txt > ${CHROMOSOME}_${START_COORD}_anchor2.txt
    awk 'ARGIND==1{fdic[$1][NR]=$3}ARGIND==2{sdic[$1][NR]=$3}END{for(id in fdic){for(peak1 in fdic[id]){for(peak2 in sdic[id])print id,fdic[id][peak1],sdic[id][peak2]}}}' ${CHROMOSOME}_${START_COORD}_anchor1.txt ${CHROMOSOME}_${START_COORD}_anchor2.txt | awk '{dic[$2][$3]++}END{for(i in dic)for(j in dic[i])print i,j,dic[i][j]}' | awk 'BEGIN{OFS="\t"}$1<=$2{print $1,$2,$3}' > ${CHROMOSOME}_${START_COORD}_long.txt
    let num=($END_COORD-$START_COORD)/$STEP
    awk -v n=$num 'BEGIN{for(i=1;i<=n;i++){for(j=i;j<=n;j++)data[i,j]=0}}{data[$1,$2]=$3}END{for(i=1;i<=n;i++){for(j=i;j<=n;j++)print i,j,data[i,j]}}' ${CHROMOSOME}_${START_COORD}_long.txt | awk 'BEGIN{OFS="\t"}{print $1,$2,$3}'> ${CHROMOSOME}_${START_COORD}_full.txt
    hicConvertFormat -m ${CHROMOSOME}_${START_COORD}_full.txt --bedFileHicpro ${CHROMOSOME}_${START_COORD}_abs.bed --inputFormat hicpro --outputFormat h5 -o ${CHROMOSOME}_${START_COORD}_gaussian_matrix.h5
    hicPlotMatrix -m ${CHROMOSOME}_${START_COORD}_gaussian_matrix.h5 -o ${CHROMOSOME}_${START_COORD}_gaussian_matrix.png
    rm ${CHROMOSOME}_${START_COORD}_raw.txt ${CHROMOSOME}_${START_COORD}_bin_step.bed ${CHROMOSOME}_${START_COORD}_abs.bed ${CHROMOSOME}_${START_COORD}_anchor1.txt ${CHROMOSOME}_${START_COORD}_anchor2.txt ${CHROMOSOME}_${START_COORD}_long.txt ${CHROMOSOME}_${START_COORD}_full.txt
    else
    if [ -z "$BACKGROUND" ]; then
        echo "Error: Missing background file." >&2
        exit 1
    fi
    echo "  Window size: $WINDOW_SIZE"
    echo "  Step: $STEP"
    echo " Background: $BACKGROUND"
    awk -v start=$START_COORD -v end=$END_COORD '{if($2>start&&$5<end)print $1,$2,$3,$4,$5,$6,$7}' $INTERACTION_DIR"/"$CHROMOSOME".bedpe" > ${CHROMOSOME}_${START_COORD}_raw.txt
    awk -v step=$STEP -v window=$WINDOW_SIZE -v start=$START_COORD -v end=$END_COORD 'BEGIN{for(i=start;i<end;i+=step)print i"\t"i+window}' | awk '{print $0"\t"NR}' > ${CHROMOSOME}_${START_COORD}_bin_step.bed
    awk -v chr=$CHROMOSOME -v step=$STEP 'BEGIN{OFS="\t"}{print chr,$1,$1+step,$3}' ${CHROMOSOME}_${START_COORD}_bin_step.bed > ${CHROMOSOME}_${START_COORD}_abs.bed
    awk 'ARGIND==1{dic[$3][1]=$1;dic[$3][2]=$2}ARGIND==2{for(peak in dic){if($2>dic[peak][1]&&$2<dic[peak][2])print $7,$2,peak}}' ${CHROMOSOME}_${START_COORD}_bin_step.bed ${CHROMOSOME}_${START_COORD}_raw.txt > ${CHROMOSOME}_${START_COORD}_anchor1.txt
    awk 'ARGIND==1{dic[$3][1]=$1;dic[$3][2]=$2}ARGIND==2{for(peak in dic){if($5>dic[peak][1]&&$5<dic[peak][2])print $7,$5,peak}}' ${CHROMOSOME}_${START_COORD}_bin_step.bed ${CHROMOSOME}_${START_COORD}_raw.txt > ${CHROMOSOME}_${START_COORD}_anchor2.txt
    awk 'ARGIND==1{fdic[$1][NR]=$3}ARGIND==2{sdic[$1][NR]=$3}END{for(id in fdic){for(peak1 in fdic[id]){for(peak2 in sdic[id])print id,fdic[id][peak1],sdic[id][peak2]}}}' ${CHROMOSOME}_${START_COORD}_anchor1.txt ${CHROMOSOME}_${START_COORD}_anchor2.txt | awk '{dic[$2][$3]++}END{for(i in dic)for(j in dic[i])print i,j,dic[i][j]}' | awk 'BEGIN{OFS="\t"}$1<=$2{print $1,$2,$3}' > ${CHROMOSOME}_${START_COORD}_long.txt
    let num=($END_COORD-$START_COORD)/$STEP
    awk -v n=$num 'BEGIN{for(i=1;i<=n;i++){for(j=i;j<=n;j++)data[i,j]=0}}{data[$1,$2]=$3}END{for(i=1;i<=n;i++){for(j=i;j<=n;j++)print i,j,data[i,j]}}' ${CHROMOSOME}_${START_COORD}_long.txt | awk 'BEGIN{OFS="\t"}{print $1,$2,$3}'> ${CHROMOSOME}_${START_COORD}_full.txt
    paste ${CHROMOSOME}_${START_COORD}_full.txt ${BACKGROUND} | awk 'BEGIN{OFS="\t"}{print $1,$2,($3+1)/($6+1)}' > ${CHROMOSOME}_${START_COORD}_norm.txt
    hicConvertFormat -m ${CHROMOSOME}_${START_COORD}_norm.txt --bedFileHicpro ${CHROMOSOME}_${START_COORD}_abs.bed --inputFormat hicpro --outputFormat h5 -o ${CHROMOSOME}_${START_COORD}_correct_matrix.h5
    hicPlotMatrix -m ${CHROMOSOME}_${START_COORD}_correct_matrix.h5 -o ${CHROMOSOME}_${START_COORD}_correct_matrix.png
    rm ${CHROMOSOME}_${START_COORD}_raw.txt ${CHROMOSOME}_${START_COORD}_bin_step.bed ${CHROMOSOME}_${START_COORD}_abs.bed ${CHROMOSOME}_${START_COORD}_anchor1.txt ${CHROMOSOME}_${START_COORD}_anchor2.txt ${CHROMOSOME}_${START_COORD}_long.txt ${CHROMOSOME}_${START_COORD}_full.txt ${CHROMOSOME}_${START_COORD}_norm.txt
 
fi
echo "Conversion completed."
