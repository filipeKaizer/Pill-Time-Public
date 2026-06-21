import os
import asyncio
from pathlib import Path
from ultralytics import YOLO
class ImageValidationUnavailable(Exception):
    pass

class MedicineImageValidator:
    DEFAULT_ULTRALYTICS_MODEL = "yolo26x.pt"

    def __init__(self, model_path, confidence=0.45, medicine_classes=None, database=None):
        self.model_path = self._resolve_model_path(model_path)
        self.confidence = confidence
        self.medicine_classes = self._normalize_classes(
            medicine_classes
        )
        self.model = None
        self.loaded_model_path = None
        self.database = database

    async def start_worker(self, memory):
        print("Worker YOLO iniciado")
        while True:
            try:
                # espera nova imagem
                image = await memory.get_image()

                print(f"Processando imagem: {image.full_path}")

                is_medicine = self.is_medicine_image(image.full_path)

                if not is_medicine:
                    print("Imagem rejeitada")
                    image.remove()
                else:
                    print("Imagem aprovada")

                    self.database.save_image_id(image.remedy,image.full_path)

            except Exception as e:
                print("Erro no worker YOLO:",e)
            finally:
                # libera a fila
                memory.images_queue.task_done()

    def _api_root(self):
        return Path(__file__).resolve().parents[1]

    def _resolve_model_path(self, model_path):
        if not model_path:
            return None

        path = Path(model_path)

        if path.is_absolute():
            return path

        return self._api_root() / path

    def _default_model_path(self):
        return self._api_root() / self.DEFAULT_ULTRALYTICS_MODEL

    def _normalize_classes(self, classes):
        if not classes:
            classes = [
                "medicine",
                "medication",
                "remedy",
                "drug",
                "pill",
                "box"
            ]
        return {
            c.lower().strip()
            for c in classes
        }

    def _load_model(self):
        if self.model:
            return
        
        if self.model_path and self.model_path.is_file():
            self.model = YOLO(str(self.model_path))
            self.loaded_model_path = self.model_path
        else:
            path = self._default_model_path()
            self.model = YOLO(str(path))
            self.loaded_model_path = path

    def load_model(self):
        self._load_model()
        return self.loaded_model_path

    def is_medicine_image(self, image_path):
        self._load_model()

        results = self.model.predict(source=image_path, conf=self.confidence, verbose=False)

        for result in results:
            names = result.names or {}

            for box in result.boxes:
                class_id = int(box.cls[0])
                class_name = (names[class_id].lower().strip())

                confidence = float(box.conf[0])

                if self._is_accepted_class(class_name):
                    print(f"YOLO aprovado: {class_name} {confidence:.2f}")
                    return True
        return False

    def _is_accepted_class(self, name):
        if "*" in self.medicine_classes:
            return True
        return name in self.medicine_classes