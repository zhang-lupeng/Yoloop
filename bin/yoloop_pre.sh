#!/bin/bash
# yoloop_pre.sh - Yoloop preprocessing module

# Display usage information
usage() {
    echo "Usage: $0 -i <interaction_file> -g <genome_size_file> "
    echo "Options:"
    echo "  -i  Interaction file (required)"
    echo "  -g  Genome size file (required)"
    exit 1
}


# Parse command line arguments
while getopts ":i:g:" opt; do
    case $opt in
        i) INTERACTION_FILE=$OPTARG ;;
        g) GENOME_SIZE_FILE=$OPTARG ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# Check required arguments
if [ -z "$INTERACTION_FILE" ] || [ -z "$GENOME_SIZE_FILE" ]; then
    echo "Error: Missing required arguments"
    usage
fi

# Verify file existence
if [ ! -f "$INTERACTION_FILE" ]; then
    echo "Error: Interaction file $INTERACTION_FILE not found"
    exit 1
fi

if [ ! -f "$GENOME_SIZE_FILE" ]; then
    echo "Error: Genome size file $GENOME_SIZE_FILE not found"
    exit 1
fi

# Main processing function
process_interactions() {
    echo "Starting preprocessing..."
    echo "Input file: $INTERACTION_FILE"
    echo "Genome size file: $GENOME_SIZE_FILE"
    
    # 1. Load genome sizes into associative array
    declare -A CHROM_SIZES
    while IFS=$'\t' read -r chrom size; do
        CHROM_SIZES[$chrom]=$size
    done < "$GENOME_SIZE_FILE"
    # 2. Default output is yo_out
    DIR="./yo_out"
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR" 
    fi

    # 3. Process interaction file
    cat $GENOME_SIZE_FILE | while read id;
    do
    chr=`echo $id | cut -d " " -f1`
    awk 'BEGIN{OFS="\t"}$2~$5&&$2~/'"$chr"'/{print $2,$3,$3+1,$5,$6,$6+1,NR}' $INTERACTION_FILE > yo_out/${chr}.bedpe
    done
 
    echo "Preprocessing completed! "
}

# Execute main function
process_interactions
