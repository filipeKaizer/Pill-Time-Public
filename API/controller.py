from flask import Flask
from services.database import Database
from services.flask_service import Flask_service
from services.config import Config
from services.image_validator import ImageValidationUnavailable
from image import Image
from services.image_validator import ImageValidationUnavailable, MedicineImageValidator
from memory import Memory
import os
class Controller:
    def __init__(self):
        # Parametros de funcionamento
        self.config = Config()

        # Base de dados
        self.database = Database(
            db_name=self.config.db_database,
            user=self.config.db_user,
            password=self.config.db_password,
            ip=self.config.db_ip,
            port=self.config.db_port
        )

        # Flask
        self.flask = Flask(__name__)
        
        # Memóri
        self.memory = Memory()

        # Validador de imagens
        self.image_validator = MedicineImageValidator(
            model_path=controller.config.yolo_model_path,
            confidence=controller.config.yolo_confidence,
            medicine_classes=controller.config.yolo_medicine_classes,
        )

        # Adiciona as rotas do Flask
        self.flask_service = Flask_service(self)

    def newImage(self, image : Image):
        self.memory.newImage(image)
        try:
            is_medicine_image = self.image_validator.is_medicine_image(image.full_path)
        except ImageValidationUnavailable as e:
            print("Erro na verificação de imagem:", e)
            os.remove(image.full_path)
 
        if not is_medicine_image:
            os.remove(image.full_path)

        # salva caminho da imagem no banco
        self.database.save_image_id(image.remedy, image.full_path)

    def run(self):
        try:
            print("Carregando modelo YOLO...")
            model_path = self.flask_service.load_image_model()
        except ImageValidationUnavailable as e:
            print("API nao esta pronta. Erro ao carregar modelo YOLO:", e)
            raise SystemExit(1) from e

        print(f"Modelo YOLO carregado: {model_path}")
        print(f"API pronta para operar em http://0.0.0.0:{self.config.flask_port}")
        self.flask.run(
            debug=True,
            port=self.config.flask_port,
            host='0.0.0.0',
            use_reloader=False,
        )


if __name__ == "__main__":
    controller = Controller()
    controller.run()
