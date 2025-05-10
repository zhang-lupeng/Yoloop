#!/bin/bash

# YOLO Object Detection Script
# Usage: ./yoloop_detect.sh -m <model> -c <class> -i <input_dir> -t [conf]

# Initialize variables
MODEL=""
CLASS_FILE=""
INPUT_DIR=""
OUTPUT_DIR="recongnize"
CONF=0.6

# Parse command line arguments
while getopts ":m:c:i:o:" opt; do
  case $opt in
    m) MODEL="$OPTARG"   # Path to YOLO model file
    ;;
    c) CLASS_FILE="$OPTARG"   # Path to class labels file
    ;;
    i) INPUT_DIR="$OPTARG"   # Directory containing input JPG images
    ;;
    t) CONF="$OPTARG"   # Confidence threshold (0-1)
    ;;
    \?) echo "Invalid option: -$OPTARG" >&2
       exit 1
    ;;
    :) echo "Option -$OPTARG requires an argument." >&2
       exit 1
    ;;
  esac
done

# Check if required parameters are provided
if [ -z "$MODEL" ] || [ -z "$CLASS_FILE" ] || [ -z "$INPUT_DIR" ] ; then
    echo "Error: Missing required parameters!"
    echo "Usage: $0 -m <model> -c <class> -i <input_dir> -t [confidence]"
    echo "Options:"
    echo "  -m  Path to YOLO model file (required)"
    echo "  -c  Path to class file (required)"
    echo "  -i  Directory containing input JPG images (required)"
    echo "  -t  Confidence threshold (0-1) (default:0.6)"
    exit 1
fi
# Validate confidence threshold is a number between 0 and 1
if ! [[ "$CONF" =~ ^[0-9]+([.][0-9]+)?$ ]] || \
    (( $(echo "$CONF < 0" | bc -l) )) || \
    (( $(echo "$CONF > 1" | bc -l) )); then
    echo "Error: Confidence threshold must be a number between 0 and 1"
    exit 1
fi

# Verify input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory does not exist!"
    exit 1
fi

# Verify model file exists
if [ ! -f "$MODEL" ]; then
    echo "Error: Model file does not exist!"
    exit 1
fi

# Verify class file exists
if [ ! -f "$CLASS_FILE" ]; then
    echo "Error: Class file does not exist!"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Process each JPG file in input directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
python ${SCRIPT_DIR}/predict.py $MODEL $CLASS_FILE $INPUT_DIR $OUTPUT_DIR
sh ${SCRIPT_DIR}/picture2genome.sh $OUTPUT_DIR
echo "Processing complete!" 
