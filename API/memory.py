import asyncio

class Memory:
    def __init__(self):
        self.remedies = None
        self.images_queue = asyncio.Queue()

    async def newImage(self, image):
        await self.images_queue.put(image)

    async def get_image(self):
        return await self.images_queue.get()