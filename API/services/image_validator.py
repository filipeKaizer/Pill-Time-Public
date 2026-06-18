import os
from pathlib import Path


class ImageValidationUnavailable(Exception):
    pass


class MedicineImageValidator:
    DEFAULT_ULTRALYTICS_MODEL = "yolo26x.pt"

    def __init__(
        self,
        model_path,
        confidence=0.45,
        medicine_classes=None,
    ):
        self.model_path = self._resolve_model_path(model_path)
        self.confidence = confidence
        self.medicine_classes = self._normalize_classes(medicine_classes)
        self.model = None
        self.loaded_model_path = None

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

    def _normalize_classes(self, medicine_classes):
        if not medicine_classes:
            medicine_classes = [
                "medicine",
                "medication",
                "remedy",
                "drug",
                "pill",
                'box',
            ]

        return {name.strip().lower() for name in medicine_classes if name.strip()}

    def _load_model(self):
        if self.model is not None:
            return

        try:
            from ultralytics import YOLO
        except ImportError as e:
            raise ImageValidationUnavailable(
                "Package 'ultralytics' is not installed"
            ) from e

        if self.model_path is None:
            default_model_path = self._default_model_path()
            print(
                "YOLO_MODEL_PATH is not configured. "
                f"Using {default_model_path}."
            )
            self.model = self._load_ultralytics_model(YOLO, default_model_path)
            self.loaded_model_path = default_model_path
            return

        if self.model_path.is_file():
            self.model = self._create_yolo_model(YOLO, str(self.model_path))
            self.loaded_model_path = self.model_path
            return

        default_model_path = self._default_model_path()
        print(
            f"YOLO model file not found: {self.model_path}. "
            f"Downloading and using {default_model_path}."
        )
        self.model = self._load_ultralytics_model(YOLO, default_model_path)
        self.loaded_model_path = default_model_path

    def _load_ultralytics_model(self, yolo_class, model_path):
        if model_path.is_file():
            return self._create_yolo_model(yolo_class, str(model_path))

        current_directory = os.getcwd()
        try:
            os.chdir(self._api_root())
            return self._create_yolo_model(yolo_class, model_path.name)
        finally:
            os.chdir(current_directory)

    def _create_yolo_model(self, yolo_class, model_reference):
        try:
            return yolo_class(model_reference)
        except Exception as e:
            raise ImageValidationUnavailable(
                f"Could not load YOLO model: {model_reference}"
            ) from e

    def load_model(self):
        self._load_model()
        return self.loaded_model_path

    def is_medicine_image(self, image_path):
        self._load_model()

        results = self.model.predict(
            source=image_path,
            conf=self.confidence,
            verbose=False,
        )

        class_name = ""
        confidence = 0
        for result in results:
            names = result.names or {}

            for box in result.boxes:
                class_id = int(box.cls[0])
                class_name = str(names.get(class_id, "")).strip().lower()
                confidence = float(box.conf[0])

                if self._is_accepted_class(class_name):
                    print(f"Imagem aceita pelo YOLO: {class_name} ({confidence:.2f})")
                    return True
                
        print(f"YOLO: {class_name} ({confidence:.2f})")
        print(f"Imagem rejeitada pelo YOLO.")
        return False

    def _is_accepted_class(self, class_name):
        if "*" in self.medicine_classes:
            return True

        return class_name in self.medicine_classes
