import asyncio
import threading
from datetime import datetime
from flask import Flask

from services.database import Database
from services.flask_service import Flask_service
from services.config import Config
from services.image_validator import (ImageValidationUnavailable, MedicineImageValidator)
from memory import Memory


class Controller:
    def __init__(self):
        # Configurações
        self.config = Config()
        # Banco de dados
        self.database = Database(
            db_name=self.config.db_database,
            user=self.config.db_user,
            password=self.config.db_password,
            ip=self.config.db_ip,
            port=self.config.db_port
        )
        # Flask
        self.flask = Flask(__name__)
        # Memória / fila de imagens
        self.memory = Memory()
        # Validador YOLO
        self.image_validator = MedicineImageValidator(
            model_path=self.config.yolo_model_path,
            confidence=self.config.yolo_confidence,
            medicine_classes=self.config.yolo_medicine_classes,
            database=self.database
        )
        # Rotas Flask
        self.flask_service = Flask_service(self)
        self.last_remedie_refresh = datetime.now()

    def newImage(self, image):
        # salva o arquivo enquanto o upload ainda está aberto
        image.save()
        # adiciona somente o objeto já salvo na fila
        asyncio.run_coroutine_threadsafe(
            self.memory.newImage(image),
            self.async_loop
        )

    def start_image_validator_worker(self):
        """
        Inicia o loop assíncrono responsável
        pelo processamento das imagens.
        """
        self.async_loop = asyncio.new_event_loop()

        asyncio.set_event_loop(self.async_loop)

        self.async_loop.create_task(self.image_validator.start_worker(self.memory))

        print("Worker de validação de imagens iniciado")
        self.async_loop.run_forever()

    def start_worker_thread(self):
        """
        Executa o worker em uma thread separada
        para não bloquear o Flask.
        """
        thread = threading.Thread(
            target=self.start_image_validator_worker,
            daemon=True
        )
        thread.start()

    def getRemedies(self):
        if self.memory.remedies is None or self.last_remedie_refresh is None or (datetime.now() - self.last_remedie_refresh).seconds > 30:
            self.memory.remedies = self.database.getAllRemedies()
            self.last_remedie_refresh = datetime.now()
        
        return self.memory.remedies

    def run(self):
        try:
            print("Carregando modelo YOLO...")
            model_path = (self.image_validator.load_model())
        except ImageValidationUnavailable as e:
            print("API não está pronta. Erro ao carregar YOLO:", e)
            raise SystemExit(1)

        print(f"Modelo YOLO carregado: {model_path}")

        # inicia processamento assíncrono
        self.start_worker_thread()
        print(f"API pronta em http://0.0.0.0:{self.config.flask_port}")

        self.flask.run(
            debug=True,
            host="0.0.0.0",
            port=self.config.flask_port,
            use_reloader=False
        )

if __name__ == "__main__":
    controller = Controller()
    controller.run()