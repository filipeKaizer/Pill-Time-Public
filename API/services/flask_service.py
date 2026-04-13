import base64
from flask import Flask, request, jsonify, send_from_directory, url_for
import os

class Flask_service:
    
    def __init__(self, controller):
        self.controller = controller

        # Inicializa as rotas
        @controller.flask.route('/uploadImage', methods=['POST', 'GET'])
        def upload_image():
            '''
            Rota para o envio de imagens
            '''
            if "image" not in request.files:
                return jsonify({
                    'status': 'error'
                }), 400
            
            remedy = request.args.get('remedy')
            if not remedy:
                return jsonify({
                    'status': 'error',
                    'message': 'remedy parameter is required'
                }), 400
            
            image_id = self.controller.database.get_next_image_id()

            # Salva a imagem
            image = request.files["image"]

            path = os.path.join(".", f"{image_id}{os.path.splitext(image.filename)[1]}")
            image.save(dst=path)

            # Adiciona na base de dados
            res = self.controller.database.save_image_id(remedy, path)

            return jsonify(
                {
                    'status': "Error" 
                }
            )
        


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
                filename = os.path.basename(path)

                with open(filename, "rb") as img_file:
                    encoded = base64.b64encode(img_file.read()).decode('utf-8')

                    images.append({
                        "filename": filename,
                        "data": encoded
                    })

            return jsonify({'images': images})


        @controller.flask.route('/images/<filename>')
        def serve_image(filename):
            root_dir = os.getcwd()

            file_path = os.path.join(root_dir, filename)

            if not os.path.isfile(file_path):
                ...

            return send_from_directory(root_dir, filename)
        
        @controller.flask.route('/getRemedies', methods=['GET'])
        def getRemedyInfo():
            '''
            Obtem os dados de todos os remedios
            '''
            return jsonify(self.controller.database.getAllRemedies())
        

            
            