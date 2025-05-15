#yoloop_APA.sh - Script for generating APA (aggrate plot analysis)
# Required parameters:
#   -l: Loop file (anchor regions)
#   -f: Original interaction file in BEDPE format
#   -o: output file name
# Optional parameters:
#   -s: Heatmap minimum value (default: 0)
#   -m: Heatmap maximum value (default: 1)

# Initialize default values
MIN_VAL=""
MAX_VAL=""
LOOP_FILE=""
BEDPE_FILE=""
OUT=""
# Parse command line arguments
while getopts "l:f:o:s:m:" opt; do
    case $opt in
        l) LOOP_FILE="$OPTARG" ;;
        f) BEDPE_FILE="$OPTARG" ;;
        o) OUT="$OPTARG" ;;
        s) MIN_VAL="$OPTARG" ;;
        m) MAX_VAL="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
    esac
done

# Check if required parameters are provided
if [ -z "$LOOP_FILE" ] || [ -z "$BEDPE_FILE" ] || [ -z "$OUT" ]; then
    echo "Error: -l (loop file bedpe format), -f (interaction file pgl format) and -o (output file name) parameters are required"
    echo "Usage: $0 -l <loop_file> -f <bedpe_file> -o <out_name> [-s min_value] [-m max_value]"
    exit 1
fi

# Check if input files exist
if [ ! -f "$LOOP_FILE" ]; then
    echo "Error: Loop file $LOOP_FILE does not exist"
    exit 1
fi

if [ ! -f "$BEDPE_FILE" ]; then
    echo "Error: BEDPE file $BEDPE_FILE does not exist"
    exit 1
fi

Ran=$RANDOM
awk 'BEGIN{OFS="\t"}{print $1,int(($2+$3)/2),int(($2+$3)/2)+1,$4,int(($5+$6)/2),int(($5+$6)/2)+1,$7,$8}' $LOOP_FILE | awk 'BEGIN{OFS="\t"}{print $1,$2-1000,$3+1000,$4,$5-1000,$6+1000,$7,$8}' | awk '$3<$5{print $0}' > ${Ran}_loop_apa.bedpe
num_loop=`wc -l ${Ran}_loop_apa.bedpe | cut -d " " -f1`

pgltools formatbedpe ${Ran}_loop_apa.bedpe > ${Ran}_loop_apa.pgl
pgltools intersect -a ${Ran}_loop_apa.pgl -b $BEDPE_FILE -wo > ${Ran}_loop_apa_raw.pgl

awk 'BEGIN{OFS="\t"}{a=int(($8-$2)/100);b=int(($11-$5)/100);dic[$15 "\t" $16][a "\t" b]++}END{for(l in dic){printf "%s\t",l;for(m=0;m<20;m++)for(n=m;n<20;n++){if((m "\t" n) in dic[l])printf "%d\t",dic[l][m "\t" n];else printf "%d\t",0};printf "\n"}}' ${Ran}_loop_apa_raw.pgl > ${Ran}_raw_matrix.txt

awk '{for(i=3;i<=NF;i++)dic[i]+=$i}END{for(n in dic)print n,dic[n]}' ${Ran}_raw_matrix.txt | sort -k 1,1n > ${Ran}_long_matrix.txt

awk 'BEGIN{for(i=0;i<20;i++)for(j=i;j<20;j++)print i,j}' > ${Ran}_index.txt

paste ${Ran}_index.txt ${Ran}_long_matrix.txt > ${Ran}_long_matrix_index.txt 
awk 'BEGIN{OFS="\t"}{dic[$1 "\t" $2]=$4}END{for(i=0;i<20;i++)for(j=0;j<20;j++)if((i "\t" j) in dic)print i,j,dic[i "\t" j];else print i,j,dic[j "\t" i]}' ${Ran}_long_matrix_index.txt | awk -v n=$num_loop '{print $3/n}' | xargs -n 20 > ${OUT}_matrix.txt

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
Rscript $SCRIPT_DIR/APA_plot_heatmap.r ${OUT}_matrix.txt $MIN_VAL $MAX_VAL
rm ${Ran}_loop_apa.bedpe ${Ran}_loop_apa.pgl ${Ran}_loop_apa_raw.pgl ${Ran}_raw_matrix.txt ${Ran}_long_matrix.txt ${Ran}_index.txt ${Ran}_long_matrix_index.txt

