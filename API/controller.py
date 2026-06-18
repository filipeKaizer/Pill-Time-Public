from flask import Flask
from services.database import Database
from services.flask_service import Flask_service
from services.config import Config
from services.image_validator import ImageValidationUnavailable

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

        # Adiciona as rotas do Flask
        self.flask_service = Flask_service(self)

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
