from image import Image

class Memory:
    def __init__(self):
        # Remédios
        self.remedies = []
        # Buffer de imagens
        self.image_buffer = []

    def newImage(self, image : Image):        
        self.image_buffer.append(image)