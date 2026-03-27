from flask import Flask
from services.database import Database
from services.flask_service import Flask_service
from services.config import Config

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
        Flask_service(self)

    def run(self):
        self.flask.run(debug=True, port=self.config.flask_port, host='0.0.0.0')


if __name__ == "__main__":
    controller = Controller()
    controller.run()