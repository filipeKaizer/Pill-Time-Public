import base64
from flask import Flask, request, jsonify, send_from_directory
import os
from image import Image

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from controller import Controller

class Flask_service:

    def __init__(self, controller : "Controller"):
        self.controller = controller
        self.image_path = controller.config.image_folder

        # Garante que a pasta existe
        os.makedirs(self.image_path, exist_ok=True)

        # UPLOAD
        @controller.flask.route('/uploadImage', methods=['POST'])
        def upload_image():
            if "image" not in request.files:
                return jsonify({'status': 'error', 'message': 'No image sent'}), 400

            remedy = request.args.get('remedy')
            if not remedy:
                return jsonify({
                    'status': 'error',
                    'message': 'remedy parameter is required'
                }), 400

            image = request.files["image"]
            image_id = self.controller.database.get_next_image_id()

            image_obj = Image(id=image_id, image=image, image_path=self.image_path, remedy=remedy)

            self.controller.newImage(image=image_obj)

            return jsonify({
                'status': 'success',
                'filename': image.filename,
                'medicine_image': True
            }), 200

        # GET IMAGENS (BASE64)
        @controller.flask.route('/image', methods=['GET'])
        def get_image():
            remedy_id = request.args.get('remedy')

            if not remedy_id:
                return jsonify({'error': 'remedy parameter is required'}), 400

            image_paths = self.controller.database.getRemedyImages(remedy_id)

            if not image_paths:
                return jsonify({'error': 'No images found'}), 404

            images = []

            for path in image_paths:

                if not os.path.isfile(path):
                    continue

                with open(path, "rb") as img_file:
                    encoded = base64.b64encode(img_file.read()).decode('utf-8')

                    images.append({
                        "filename": os.path.basename(path),
                        "data": encoded
                    })

            return jsonify({'images': images})

        # SERVE IMAGEM DIRETA
        @controller.flask.route('/images/<filename>')
        def serve_image(filename):

            file_path = os.path.join(self.image_path, filename)

            if not os.path.isfile(file_path):
                return jsonify({'error': 'File not found'}), 404

            # usa a pasta de imagens
            return send_from_directory(self.image_path, filename)

        # REMEDIOS
        @controller.flask.route('/getRemedies', methods=['GET'])
        def getRemedyInfo():
            return jsonify(self.controller.database.getAllRemedies())

    def load_image_model(self):
        return self.image_validator.load_model()
