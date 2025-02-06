#!/bin/bash

# Function to display help message
show_help() {
    echo "Usage: $0 --input FILE --bitrate BITRATE --ip IP --port PORT --codec CODEC --width WIDTH --height HEIGHT --keyint KEYINT --gop GOP --save-fps FPS --output-dir DIRECTORY"
    echo
    echo "Options:"
    echo "  --input      Input video file (required)"
    echo "  --bitrate    Bitrate for the video (default: 1M)"
    echo "  --ip         Destination IP address (required)"
    echo "  --port       Destination port (default: 8554)"
    echo "  --codec      Video codec (required) [h264, h265, vp9]"
    echo "  --width      Width for the resolution (default: 1280)"
    echo "  --height     Height for the resolution (default: 720)"
    echo "  --keyint     Keyframe interval (default: 30)"
    echo "  --gop        GOP size (default: 30)"
    echo "  --save-fps   Frame rate to save frames (default: no FPS limit)"
    echo "  --output-dir Directory to save frames (default: none)"
    echo "  --help       Display this help message"
    echo
    echo "Examples:"
    echo "  $0 --input /path/to/video.avi --bitrate 1M --ip 127.0.0.1 --port 8554 --codec h264 --keyint 60 --gop 60 --save-fps 15 --output-dir ./frames"
    echo "  $0 --input /path/to/video.avi --bitrate 500K --ip 127.0.0.1 --port 8554 --codec h264 --keyint 30 --gop 30 --save-fps 0.5 --output-dir ./frames"
    echo "  $0 --input /path/to/video.avi --bitrate 500K --ip 127.0.0.1 --port 8554 --codec vp9 --keyint 30 --gop 30"
}

# Default values
bitrate="1M"
port="8554"
width="1280"
height="720"
keyint="30"  # Default keyframe interval
gop="30"     # Default GOP size
save_fps=""   # Default FPS is unset
output_dir="" # Default no output directory

# Parse named arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --input) input_file="$2"; shift 2 ;;
        --bitrate) bitrate="$2"; shift 2 ;;
        --ip) ip="$2"; shift 2 ;;
        --port) port="$2"; shift 2 ;;
        --codec) codec="$2"; shift 2 ;;
        --width) width="$2"; shift 2 ;;
        --height) height="$2"; shift 2 ;;
        --keyint) keyint="$2"; shift 2 ;;
        --gop) gop="$2"; shift 2 ;;
        --save-fps) save_fps="$2"; shift 2 ;;
        --output-dir) output_dir="$2"; shift 2 ;;
        --help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$input_file" || -z "$ip" || -z "$codec" ]]; then
    echo "Error: Missing required arguments."
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

# Resolution string for ffmpeg
scale="$width:$height"

# Frame-saving logic
frame_save_args=""
if [[ -n "$output_dir" ]]; then
    frame_save_args="-map 0:v:0 -c:v bmp -pix_fmt bgr24 $output_dir/frame_%04d.bmp"
    if [[ -n "$save_fps" ]]; then
        frame_save_args="-vf fps=$save_fps $frame_save_args"
    fi
fi

# Process based on codec
case "$codec" in
    h264)
        echo "Using h264 codec"
        ffmpeg -re -i "$input_file" -vf "scale=$scale" \
            -f sdl "Sender Display" \
            -c:v libx264 -preset ultrafast -tune zerolatency -b:v "$bitrate" \
            -keyint_min "$keyint" -g "$gop" -f mpegts udp://"$ip":"$port" \
            $frame_save_args
        ;;
    h265)
        echo "Using h265 codec"
        ffmpeg -re -i "$input_file" -vf "scale=$scale" \
            -f sdl "Sender Display" \
            -c:v libx265 -preset ultrafast -tune zerolatency -b:v "$bitrate" \
            -keyint_min "$keyint" -g "$gop" -f mpegts udp://"$ip":"$port" \
            $frame_save_args
        ;;
    vp9)
        echo "Using vp9 codec"
        ffmpeg -re -i "$input_file" -vf "scale=$scale" \
            -f sdl "Sender Display" \
            -c:v libvpx-vp9 -b:v "$bitrate" -g "$gop" -f webm udp://"$ip":"$port" \
            $frame_save_args
        ;;
    *)
        echo "Error: Unsupported codec '$codec'. Supported codecs are h264, h265, vp9."
        exit 1
        ;;
esac
