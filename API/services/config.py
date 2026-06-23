from dotenv import load_dotenv
import os

class Config:
    def __init__(self):
        load_dotenv()

        # Database
        self.db_password = os.getenv("DB_PASSWORD")
        self.db_user = os.getenv("DB_USER")
        self.db_ip = os.getenv("DB_IP")
        self.db_port = os.getenv("DB_PORT")
        self.db_database = os.getenv("DB_DATABASE")

        # Images
        self.image_folder = os.getenv("IMAGE_FOLDER")
        self.yolo_model_path = os.getenv("YOLO_MODEL_PATH")
        self.yolo_confidence = float(os.getenv("YOLO_CONFIDENCE", "0.45"))
        self.yolo_medicine_classes = [
            item.strip()
            for item in os.getenv("YOLO_MEDICINE_CLASSES", "").split(",")
            if item.strip()
        ]

        # Flask
        self.flask_port = os.getenv("FLASK_PORT")
        
