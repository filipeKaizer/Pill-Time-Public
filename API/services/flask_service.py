from flask import Flask, request, jsonify, send_from_directory, url_for
import os

class Flask_service:
    
    def __init__(self, controller):
        self.controller = controller

        # Inicializa as rotas
        @controller.flask.route('/uploadImage', methods=['POST'])
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

            image_path = os.path.join(self.controller.config.image_folder, image_id)
            image.save(image_path)

            # Adiciona na base de dados
            self.controller.database.save_image_id(remedy, image_path)
        

        @controller.flask.route('/image', methods=['GET'])
        def get_image():
            remedyId = request.args.get('remedy')

            image_paths = self.controller.database.getRemedyImages(remedyId)

            if not image_paths:
                return jsonify({'error': 'No images found'}), 404

            images = []

            for path in image_paths:
                filename = os.path.basename(path)

                images.append(
                    url_for('serve_image', filename=filename, _external=True)
                )

            return jsonify({'images': images})
        
        @controller.flask.route('/getRemedies', methods=['GET'])
        def getRemedyInfo():
            '''
            Obtem os dados de todos os remedios
            '''
            return jsonify(self.controller.database.getAllRemedies())
        

            
            