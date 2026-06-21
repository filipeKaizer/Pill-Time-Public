import os

class Image:
    def __init__(self, id, image, remedy, image_path):
        self.id = id
        self.image = image
        self.image_path = image_path
        self.remedy = remedy
        self.full_path = self.get_full_path()
    
    def get_full_path(self):
        ext = os.path.splitext(self.image.filename)[1]
        filename = f"{self.id}{ext}"

        # salva dentro da pasta
        return os.path.join(self.image_path, filename)

    def save(self):
        self.image.save(self.full_path)
    
    def remove(self):
        ext = os.path.splitext(self.image.filename)[1]
        filename = f"{self.id}{ext}"

        # salva dentro da pasta
        full_path = os.path.join(self.image_path, filename)

        os.remove(full_path)