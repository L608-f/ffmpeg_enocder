#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 --ip IP --port PORT --output-dir DIRECTORY --fps FPS"
    echo
    echo "Options:"
    echo "  --ip           IP address to listen for incoming stream (required)"
    echo "  --port         Port to listen on (default: 8554)"
    echo "  --output-dir   Directory to save frames (default: none)"
    echo "  --save-fps          Frame rate (in frames per second) to save frames (default: no FPS limit)"
    echo "  --help         Display this help message"
    echo
    echo "Saving Frames:"
    echo "  If the --output-dir option is specified, frames will be saved as BMP images."
    echo "  The --fps option allows you to limit the frame rate at which the frames are saved."
    echo "  For example, --fps 15 will save frames at a rate of 15 frames per second."
    echo
    echo "Examples:"
    echo "  $0 --ip 127.0.0.1 --port 8554 --output-dir ./frames --save-fps 15"
    echo "    This will save frames to ./frames directory at 15 FPS."
    echo
    echo "  $0 --ip 127.0.0.1 --port 8554 --output-dir ./frames"
    echo "    This will save all frames to ./frames directory without any FPS limit."
    echo
    echo "  $0 --ip 127.0.0.1 --port 8554"
    echo "    This will just display the video on SDL without saving any frames."
}

# Default values
port="8554"
output_dir=""
fps=""

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --ip) ip="$2"; shift 2 ;;
        --port) port="$2"; shift 2 ;;
        --output-dir) output_dir="$2"; shift 2 ;;
        --save-fps) fps="$2"; shift 2 ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$ip" ]]; then
    echo "Error: Missing required argument --ip."
    show_help
    exit 1
fi

# Remove output directory if it exists and output-dir is specified
if [[ -n "$output_dir" && -d "$output_dir" ]]; then
    echo "Removing existing output directory: $output_dir"
    rm -rf "$output_dir"
fi

# Create output directory if it doesn't exist and output-dir is specified
if [[ -n "$output_dir" ]]; then
    mkdir -p "$output_dir"
fi

# Start the receiver using ffmpeg
echo "Listening for stream on $ip:$port..."
# echo "Displaying video on SDL"

# If output-dir is specified, save frames as BMP with optional FPS limiting
if [[ -n "$output_dir" ]]; then
    if [[ -n "$fps" ]]; then
        echo "Saving frames at $fps FPS to $output_dir"
        ffmpeg -i udp://"$ip":"$port" -f nut - | ffplay -\
            #-c:v rawvideo \
	    #-pix_fmt yuv420p \
            #-f sdl "Decoder" \
            -map 0:v:0 -c:v bmp -pix_fmt bgr24 -vf "fps=$fps" "$output_dir/frame_%04d.bmp"
    else
        echo "Saving frames to $output_dir without FPS limit"
        ffmpeg -i udp://"$ip":"$port" -f nut - | ffplay -\
            #-c:v rawvideo \
	    #-pix_fmt yuv420p \
            #-f sdl "Decoder" \
            -map 0:v:0 -c:v bmp -pix_fmt bgr24 "$output_dir/frame_%04d.bmp"
    fi
else
    # Just display the video on SDL without saving frames
    #echo "Stream1 ... "
    #echo udp://"$ip":"$port"
    ffmpeg -i udp://"$ip":"$port" -f nut - | sudo ffplay -
        #-c:v rawvideo \
	#-pix_fmt yuv420p \
        #-f sdl "Decoder"
fi

