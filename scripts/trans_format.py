#sys.argv[1] -> input dir including jpg and json
#sys.argv[2] -> png dir
#sys.argv[3] -> save dir

import sys
import cv2
import glob
import json
import os
import argparse
import numpy as np
from PIL import Image
from tqdm import tqdm

def trans_jpg_to_png(jpg_dir):
    os.makedirs("png")
    jpg_list = glob.glob(os.path.join(jpg_dir, '*.jpg'))
    for jpg in jpg_list:
        jpg_name = jpg.split('/')[-1][: -4]
        # 打开jpg格式的图片
        jpg_image = Image.open(jpg)
        # 将jpg图片保存为png格式
        jpg_image.save('png/' + jpg_name + '.png', 'PNG')

def convert_label_json(json_dir):
    os.makedirs("labels")
    #print(json_dir)
    json_path1 = os.listdir(json_dir)
    #print(json_path1)
    json_paths = [f for f in json_path1 if f.endswith('.json')]
    #print(json_paths)
    classes_outfile = open("classes.txt", 'w')
    classes = {}
    classes1 = []

    for json_path in tqdm(json_paths):
        # for json_path in json_paths:
        path = os.path.join(json_dir, json_path)
        # print(path)
        with open(path, 'r') as load_f:
            #print(load_f)
            json_dict = json.load(load_f, )
        h, w = json_dict['imageHeight'], json_dict['imageWidth']

        # save txt path
        txt_path = os.path.join("labels", json_path.replace('json', 'txt'))
        txt_file = open(txt_path, 'w')

        for shape_dict in json_dict['shapes']:
            label = shape_dict['label']
            if label in classes1:
                label_index = classes1.index(label)
            else:
                label_index = len(classes1)
                classes1.append(label)
            try:
                classes[label] += 1
            except KeyError:
                classes[label] = 0
            points = shape_dict['points']

            points_nor_list = []

            for point in points:
                points_nor_list.append(point[0] / w)
                points_nor_list.append(point[1] / h)

            points_nor_list = list(map(lambda x: str(x), points_nor_list))
            points_nor_str = ' '.join(points_nor_list)

            label_str = str(label_index) + ' ' + points_nor_str + '\n'
            txt_file.writelines(label_str)
    # for i in classes:
    #     classes_outfile.write(i + '\n')
    for key1, value1 in classes.items():
        classes_outfile.write(key1 + '\t' + str(value1) + '\n')
    classes_outfile.close()

trans_jpg_to_png(sys.argv[1])
convert_label_json(sys.argv[1])

