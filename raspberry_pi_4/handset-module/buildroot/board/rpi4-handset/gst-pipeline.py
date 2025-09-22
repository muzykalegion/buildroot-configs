import cv2
import signal
import sys
import time

cv2.setNumThreads(4)

def signal_handler(sig, frame):
    print("Releasing resources...")
    easycap.release()
    stream_out.release()
    print("Exiting...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

pipeline = 'v4l2src device=/dev/video0 ! image/jpeg,width=640,height=480,framerate=30/1 ! queue ! jpegdec ! queue ! videoconvert ! video/x-raw,width=640,height=480,format=BGR ! appsink sync=false drop=true'
easycap = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

pipe_out = 'appsrc ! video/x-raw,width=640,height=480,format=BGR ! videoconvert ! fbdevsink sync=false'
stream_out = cv2.VideoWriter(pipe_out, cv2.CAP_GSTREAMER, 0, 30.0, (640, 480), True)

while True:
    ret, frame = easycap.read()
    if not ret:
        print('!!! EASYCAP FRAME READ FAILURE !!!')
        continue

    cv2.putText(frame, 'TEST', (120, 120), cv2.FONT_HERSHEY_PLAIN, 2.0, (0, 0, 180), 3)
    stream_out.write(frame)
