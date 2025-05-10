from ultralytics import YOLO
import os
import wandb
os.environ["WANDB_API_KEY"] = 'KEY'
os.environ["WANDB_MODE"] = "offline"

#train
# model = YOLO('/17t/chenhx/software/ultralytics/ultralytics/cfg/models/v8/yolov8n-seg.yaml')  # 不使用预训练权重训练
model = YOLO("yolo11s.pt")  # 使用预训练权重训练

# Train the model
model.train(data='dataset.yaml', epochs=100, imgsz=640, batch=4, workers=4,device="cpu", name= 'yolov11s-detect_20250508')
