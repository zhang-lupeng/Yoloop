#!/bin/bash
# yoloop_bg.sh - Background analysis module for Yoloop software

# Display usage information
usage() {
    echo "Usage: $0 -d <interaction_dir> -a <genome_size> [-w window_size] [-s step_size] [-r heatmap_region] [-t threads] [-o output_dir]"
    echo "Options:"
    echo "  -d  Directory containing interaction files (required)"
    echo "  -a  Genome size file (required)"
    echo "  -w  Window size in base pairs (default: 300)"
    echo "  -s  Step size in base pairs (default: 10)"
    echo "  -r  Heatmap region size in base pairs (default: 20000)"
    echo "  -t  Number of threads (default: 1)"
    exit 1
}

# Validate numeric input
is_positive_integer() {
    local num="$1"
    [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt 0 ]
}

# Default parameters
WINDOW_SIZE=300
STEP_SIZE=10
#GENE_COUNT=200
HEATMAP_REGION=20000
THREADS=1
OUTPUT_DIR="./bg_results/"

# Parse command line arguments
while getopts ":d:a:w:s:r:t:" opt; do
    case $opt in
        d) INTERACTION_DIR="$OPTARG" ;;
        a) GENOME_SIZE="$OPTARG" ;;
        w) WINDOW_SIZE="$OPTARG" ;;
        s) STEP_SIZE="$OPTARG" ;;
        r) HEATMAP_REGION="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# Check required arguments
if [ -z "$INTERACTION_DIR" ] || [ -z "$GENOME_SIZE" ]; then
    echo "Error: Missing required arguments" >&2
    usage
fi

# Validate numeric parameters
if ! is_positive_integer "$WINDOW_SIZE"; then
    echo "Error: Window size must be a positive integer" >&2
    exit 1
fi

if ! is_positive_integer "$STEP_SIZE"; then
    echo "Error: Step size must be a positive integer" >&2
    exit 1
fi

if ! is_positive_integer "$HEATMAP_REGION"; then
    echo "Error: Heatmap region size must be a positive integer" >&2
    exit 1
fi

if ! is_positive_integer "$THREADS"; then
    echo "Error: Heatmap region size must be a positive integer" >&2
    exit 1
fi

if [ "$STEP_SIZE" -gt "$WINDOW_SIZE" ]; then
    echo "Error: Step size cannot be larger than window size" >&2
    exit 1
fi

# Verify input files/directories exist
if [ ! -d "$INTERACTION_DIR" ]; then
    echo "Error: Interaction directory $INTERACTION_DIR not found" >&2
    exit 1
fi

if [ ! -f "$GENOME_SIZE" ]; then
    echo "Error: Genome size file $GENOME_SIZE not found" >&2
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create output directory $OUTPUT_DIR" >&2
    exit 1
fi

# Main processing function
analyze_background() {
    echo "Starting background analysis..."
    echo "Interaction directory: $INTERACTION_DIR"
    echo "Genome size file: $GENOME_SIZE"
    echo "Window size: $WINDOW_SIZE"
    echo "Step size: $STEP_SIZE"
    echo "Heatmap region size: $HEATMAP_REGION"
    echo "Number of threads: $THREADS"
    echo "Output directory: $OUTPUT_DIR"

    # Create heatmap subdirectory

    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    bedtools random -l $HEATMAP_REGION -n 500 -g $GENOME_SIZE | awk -v w=$WINDOW_SIZE -v s=$STEP_SIZE -v d=$INTERACTION_DIR -v o=$OUTPUT_DIR '{print $1,$2,$3,w,s,d,o}' | xargs -n 1 -I {} -P $THREADS sh -c "sh $SCRIPT_DIR/bg_slide.sh {}"
    python $SCRIPT_DIR/background_plot.py $STEP_SIZE $HEATMAP_REGION 500 $OUTPUT_DIR
    awk '{for(i=1;i<=NF;i++){if(i>=NR)print NR,i,$i}}' ${HEATMAP_REGION}_background.txt > ${HEATMAP_REGION}_long.txt

}

# Execute main function
analyze_background
