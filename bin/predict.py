#sys.argv[1] -> model path
#sys.argv[2] -> classes.txt
#sys.argv[3] -> jpg dir path
#sys.argv[4] -> out txt dir path

from ultralytics import YOLO
import sys
import os
import glob
import numpy as np

def predict_figures(model_path, classes_file, jpg_dir, out_dir):
    fr1 = open(classes_file, 'r')
    lines1 = fr1.readlines()
    classes_dict = {}
    for i in range(len(lines1)):
        classes_dict[lines1[i].strip().split('\t')[0]] = str(i)
    category_index = {str(v): str(k) for k, v in classes_dict.items()}
    model = YOLO(model_path)
    jpg_list = glob.glob(os.path.join(jpg_dir, '*.jpg'))
    for jpg in jpg_list:
        jpg_name = jpg.split('/')[-1][: -4]
        results = model(jpg)
        for result in results:
            boxes = result.boxes
            if len(boxes) != 0:
                mid_outfile1 = open(out_dir + '/' + jpg_name + '.txt', 'w')
                for i in range(len(boxes)):
                    box = boxes[i]
                    x1, y1, x2, y2 = box.xyxy[0]
                    mid_outfile1.write(str(round(float(box.conf), 7)) + '\t')
                    mid_outfile1.write(str(round(float(x1), 5)) + '\t' + str(round(float(y1), 5)) + '\t' + str(round(float(x2), 5)) + '\t' + str(round(float(y2), 5)) + '\t')
                    mid_outfile1.write(category_index[str(int(box.cls))] + '\n')
                mid_outfile1.close()

predict_figures(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
