import cv2

cv2.setNumThreads(4)

pipeline = 'libcamerasrc ! video/x-raw,width=640,height=480,format=BGR ! appsink sync=false drop=true'
camera = cv2.VideoCapture(pipeline, cv2.CAP_GSTREAMER)

pipe_out = 'appsrc ! video/x-raw,width=640,height=480,format=BGR ! queue ! videoconvert ! kmssink sync=false'
stream_out = cv2.VideoWriter(pipe_out, cv2.CAP_GSTREAMER, 0, 30.0, (640, 480), True)

while True:
    ret, frame = camera.read()
    if not ret:
        print('!!! CAMERA FRAME READ FAILURE !!!')
        continue

    cv2.putText(frame, 'TEST', (120, 120), cv2.FONT_HERSHEY_PLAIN, 2.0, (0, 120, 180), 3)
    stream_out.write(frame)
