#!/bin/bash
# yoloop_label.sh - Plot heatmaps for loop label and identify

# Display usage information
usage() {
    echo "Usage: $0 -d <interaction_dir> -a <genome_size_file> -b <background file> [-w window_size] [-s step_size] [-r heatmap_region] [-t threads]"
    echo "Options:"
    echo "  -d  Directory containing interaction files (required)"
    echo "  -a  Genome size file (required)"
    echo "  -b  Background file long format (required)"
    echo "  -w  Window size in base pairs (default: 300)"
    echo "  -s  Step size in base pairs (default: 10)"
    echo "  -r  Heatmap region size in base pairs (default: 20000)"
    echo "  -t  Number of threads (default: 1)"
    exit 1
}

# Function to ensure directory path ends with /
ensure_trailing_slash() {
    local dir="$1"
        # Add trailing / if not present
            [[ "$dir" != */ ]] && dir="$dir/"
                echo "$dir"
                }

# Validate numeric input
is_positive_integer() {
    local num="$1"
    [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt 0 ]
}

# Default parameters
WINDOW_SIZE=300
STEP_SIZE=10
HEATMAP_REGION=20000
THREADS=1
OUTPUT_DIR="./plot_results/"

# Parse command line arguments
while getopts ":d:a:b:w:s:r:t:" opt; do
    case $opt in
        d) INTERACTION_DIR="$OPTARG" ;;
        a) GENOME_SIZE="$OPTARG" ;;
        b) BACKGROUND="$OPTARG" ;;
        w) WINDOW_SIZE="$OPTARG" ;;
        s) STEP_SIZE="$OPTARG" ;;
        r) HEATMAP_REGION="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        \?) echo "Invalid option -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
    esac
done

# Check required arguments
if [ -z "$INTERACTION_DIR" ] || [ -z "$GENOME_SIZE" ] || [ -z "$BACKGROUND" ]; then
    echo "Error: Missing required arguments" >&2
    usage
fi

# Ensure directory path ends with /
INTERACTION_DIR=$(ensure_trailing_slash "$INTERACTION_DIR")

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
    echo "Error: Threads must be a positive integer" >&2
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
awk '{print $1}' $GENOME_SIZE | uniq | while read c;
    do
    mkdir -p "$OUTPUT_DIR$c"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create output directory $OUTPUT_DIR$c" >&2
        exit 1
    fi
    done

# Main processing function
produce_heatmap() {
    echo "Starting background analysis..."
    echo "Interaction directory: $INTERACTION_DIR"
    echo "Genome size file: $GENOME_SIZE"
    echo "Window size: $WINDOW_SIZE"
    echo "Step size: $STEP_SIZE"
    echo "Heatmap region size: $HEATMAP_REGION"
    echo "Background : $BACKGROUND"
    echo "Number of threads: $THREADS"
    echo "Output directory: $OUTPUT_DIR"
    # Create heatmap
    SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    #let half_r=$HEATMAP_REGION/2
    #filter bottom 1%
    average_counts=`awk '{sum+=$3}END{print sum}' $BACKGROUND`
    standard=`awk -v a=$average_counts -v w=$WINDOW_SIZE -v s=$STEP_SIZE 'BEGIN{print int(a/(w/s)/50)}'`
    awk -v w=$WINDOW_SIZE -v s=$STEP_SIZE -v r=$HEATMAP_REGION -v d=$INTERACTION_DIR -v o=$OUTPUT_DIR -v b=$BACKGROUND -v st=$standard '{for(i=0;i<$2;i+=10000){print $1,i,i+r,w,s,d,o,b,st}}' $GENOME_SIZE | xargs -n 1 -I {} -P $THREADS sh -c "sh $SCRIPT_DIR/label_slide.sh {}"
    
}

# Execute main function
produce_heatmap
