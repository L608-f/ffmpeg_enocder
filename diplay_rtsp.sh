#!/bin/bash

sudo ip netns exec out35 ffplay rtsp://Admin:1234@192.168.3.10:554/stream1
