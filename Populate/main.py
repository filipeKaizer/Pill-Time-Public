from database import Database

import pandas as pd
from ddgs import DDGS
import time
import random
import requests
import tempfile
import os
from PIL import Image
import torch
import clip

# ==============================
# CONFIG
# ==============================
OUTPUT_CSV = "resultado.csv"
IMAGENS_POR_ITEM = 4
UPLOAD_URL = "http://200.18.75.25:8326/uploadImage"

HEADERS = {
    "User-Agent": "Mozilla/5.0"
}

# ==============================
# IA (CLIP)
# ==============================
device = "cuda" if torch.cuda.is_available() else "cpu"
model, preprocess = clip.load("ViT-B/32", device=device)

labels = [
    "uma caixa de remédio",
    "caixa de embalagem de medicamentos",
    "caixa farmacêutica",
    "pílulas na mão",
    "pílulas soltas",
    "close-up de comprimidos",
    "pessoa segurando comprimidos"
]

text_tokens = clip.tokenize(labels).to(device)


def is_box_image_ai(caminho):
    try:
        image = preprocess(Image.open(caminho)).unsqueeze(0).to(device)

        with torch.no_grad():
            image_features = model.encode_image(image)
            text_features = model.encode_text(text_tokens)

            logits = (image_features @ text_features.T).softmax(dim=-1)

        scores = logits[0].cpu().numpy()

        # índices positivos (caixa)
        box_score = max(scores[0], scores[1], scores[2])

        # índices negativos (não caixa)
        not_box_score = max(scores[3], scores[4], scores[5], scores[6])

        return box_score > not_box_score

    except Exception as e:
        print(f"Erro IA: {e}")
        return False


# ==============================
# DOWNLOAD
# ==============================
def baixar_imagem_temp(url):
    try:
        r = requests.get(url, headers=HEADERS, timeout=10)
        if r.status_code == 200 and "image" in r.headers.get("Content-Type", ""):
            with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as f:
                f.write(r.content)
                return f.name
    except Exception as e:
        print(f"Erro download: {e}")
    return None


# ==============================
# UPLOAD
# ==============================
def enviar_para_api(remedy_id, caminho_imagem):
    try:
        with open(caminho_imagem, "rb") as img:
            response = requests.post(
                UPLOAD_URL,
                files={"image": img},
                params={"remedy": remedy_id},
                timeout=10
            )

            return response.status_code == 200

    except Exception as e:
        print(f"Erro upload: {e}")

    return False


# ==============================
# BUSCA
# ==============================
def search_images(remedio, limite=10):
    query = f"{remedio} caixa medicamento embalagem"

    imagens = []

    try:
        with DDGS() as ddgs:
            resultados = ddgs.images(query, max_results=limite)

            for r in resultados:
                url = r.get("image")
                if url:
                    imagens.append(url)

    except Exception as e:
        print(f"Erro busca: {e}")

    return imagens


# ==============================
# PROCESSAMENTO
# ==============================
def getAllImages(remedies, ids):
    resultados = []

    for remedy, rid in zip(remedies, ids):
        print(f"\n🔎 {remedy}")

        urls = search_images(remedy)
        imagens_enviadas = []

        for url in urls:
            if len(imagens_enviadas) >= IMAGENS_POR_ITEM:
                break

            caminho = baixar_imagem_temp(url)

            if caminho:
                if is_box_image_ai(caminho):
                    print("✅ Caixa detectada")

                    if enviar_para_api(rid, caminho):
                        imagens_enviadas.append(url)
                    else:
                        print("❌ Falha upload")

                else:
                    print("🚫 Não é caixa")

                os.remove(caminho)

            time.sleep(random.uniform(0.5, 1.2))

        while len(imagens_enviadas) < IMAGENS_POR_ITEM:
            imagens_enviadas.append("")

        resultados.append({
            "id": rid,
            "nome": remedy,
            "imagem1": imagens_enviadas[0],
            "imagem2": imagens_enviadas[1],
            "imagem3": imagens_enviadas[2],
            "imagem4": imagens_enviadas[3],
        })

        time.sleep(random.uniform(1, 2))

    pd.DataFrame(resultados).to_csv(OUTPUT_CSV, index=False)
    print("\n✅ Finalizado!")


# ==============================
# MAIN
# ==============================
def main():
    database = Database(
        db_name='pill',
        ip='200.18.75.25',
        password='299792458',
        port='8324',
        user='pill'
    )

    ids, remedies = database.getRemediesName()

    getAllImages(remedies, ids)


if __name__ == "__main__":
    main()