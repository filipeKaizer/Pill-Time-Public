from ultralytics import YOLO

# Modelo que será carregado
model_path = "yolo26x.pt"

# Carrega o modelo
model = YOLO(model_path)

# Exibe as classes disponíveis
keywords = [
    "medicine",
    "pill",
    "tablet",
    "capsule",
    "drug",
    "medication",
    "bottle",
    "box"
]

print("\nClasses relacionadas:")
for class_id, class_name in model.names.items():
    if any(k in class_name.lower() for k in keywords):
        print(f"{class_id}: {class_name}")
