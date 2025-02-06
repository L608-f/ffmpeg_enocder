# ffmpeg_enocder

If input data is stream:
sudo ip netns exec out35 bash ./encoder.sh --input "rtsp://Admin:1234@192.168.3.10:554/stream1" --bitrate 1M --ip 192.168.3.7 --port 8554 --codec vp9 --keyint 60 --gop 60
write rtsp link in ""

