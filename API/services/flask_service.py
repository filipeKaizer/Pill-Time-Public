import base64
from flask import Flask, request, jsonify, send_from_directory
import os
from services.image_validator import ImageValidationUnavailable, MedicineImageValidator

class Flask_service:

    def __init__(self, controller):
        self.controller = controller
        self.image_path = controller.config.image_folder
        self.image_validator = MedicineImageValidator(
            model_path=controller.config.yolo_model_path,
            confidence=controller.config.yolo_confidence,
            medicine_classes=controller.config.yolo_medicine_classes,
        )

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

            ext = os.path.splitext(image.filename)[1]
            filename = f"{image_id}{ext}"

            # salva dentro da pasta
            full_path = os.path.join(self.image_path, filename)

            image.save(full_path)

            try:
                is_medicine_image = self.image_validator.is_medicine_image(full_path)
            except ImageValidationUnavailable as e:
                print("Erro na verificação de imagem:", e)
                os.remove(full_path)
                return jsonify({
                    'status': 'error',
                    'message': str(e)
                }), 500

            if not is_medicine_image:
                os.remove(full_path)
                return jsonify({
                    'status': 'error',
                    'message': 'Image is not recognized as a medicine image'
                }), 400

            # salva caminho da imagem no banco
            self.controller.database.save_image_id(remedy, full_path)

            return jsonify({
                'status': 'success',
                'filename': filename,
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
