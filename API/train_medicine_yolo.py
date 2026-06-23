import argparse
import json
import random
import re
import shutil
import time
import urllib.parse
import urllib.request
from pathlib import Path
from urllib.error import HTTPError, URLError

from dotenv import load_dotenv
from PIL import Image

from services.config import Config
from services.database import Database


API_ROOT = Path(__file__).resolve().parent
DATASET_ROOT = API_ROOT / "datasets" / "medicine_yolo"
MODEL_OUTPUT = API_ROOT / "models" / "medicine_yolo.pt"
DEFAULT_BASE_MODEL = "yolo26n.pt"

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125 Safari/537.36"

NEGATIVE_QUERIES = [
    "caixa de cereal produto",
    "caixa de sapato produto",
    "embalagem de brinquedo",
    "caixa de celular produto",
    "embalagem de alimento supermercado",
    "Telas escuras",
    "Objetos"
]


def request_url(url, timeout=20, referer=None):
    headers = {"User-Agent": USER_AGENT, "Accept": "text/html,application/json,*/*"}
    if referer:
        headers["Referer"] = referer
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read()


def duckduckgo_image_urls(query, max_results):
    search_url = "https://duckduckgo.com/?" + urllib.parse.urlencode({"q": query, "iax": "images", "ia": "images"})
    html = request_url(search_url).decode("utf-8", errors="ignore")
    match = re.search(r"vqd=['\"]?([^'\"&]+)", html)
    if not match:
        return []

    api_url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode({"l": "br-pt", "o": "json", "q": query, "vqd": match.group(1)})
    payload = json.loads(request_url(api_url, referer=search_url).decode("utf-8", errors="ignore"))
    return [x["image"] for x in payload.get("results", [])[:max_results] if x.get("image")]

def search_image_urls(query, max_results):
    try:
        return duckduckgo_image_urls(query, max_results)
    except Exception as e:
        print(f"Erro na busca {query}: {e}")
        return []

def safe_filename(value):
    return re.sub(r"[^a-zA-Z0-9_-]+", "_", value.lower()).strip("_")

def download_image(url, destination):
    try:
        destination.write_bytes(request_url(url))
        with Image.open(destination) as img:
            img.verify()
        with Image.open(destination) as img:
            img.convert("RGB").save(destination.with_suffix(".jpg"), "JPEG", quality=90)
        destination.unlink(missing_ok=True)
        return destination.with_suffix(".jpg")
    except Exception:
        destination.unlink(missing_ok=True)
        return None

def get_remedy_names():
    load_dotenv(API_ROOT / "services" / ".env")
    config = Config()
    db = Database(db_name=config.db_database, user=config.db_user, password=config.db_password, ip=config.db_ip, port=config.db_port)
    remedies = db.getAllRemedies()
    return sorted({r["name"] for r in remedies.values() if r.get("name")})

def collect_images(names, images_per_remedy, negative_images, pause):
    positive = DATASET_ROOT / "raw" / "medicine"
    negative = DATASET_ROOT / "raw" / "not_medicine"
    positive.mkdir(parents=True, exist_ok=True)
    negative.mkdir(parents=True, exist_ok=True)

    for name in names:
        urls = search_image_urls(f"{name} caixa medicamento", images_per_remedy)
        for i, url in enumerate(urls):
            download_image(url, positive / f"{safe_filename(name)}_{i}.jpg")
        time.sleep(pause)

    for query in NEGATIVE_QUERIES:
        urls = search_image_urls(query, max(1, negative_images // len(NEGATIVE_QUERIES)))
        for i, url in enumerate(urls):
            download_image(url, negative / f"{safe_filename(query)}_{i}.jpg")

def has_downloaded_images():
    return bool(list((DATASET_ROOT / "raw" / "medicine").glob("*.jpg")))

def prepare_dataset(val_ratio):
    for folder in ["images", "labels"]:
        shutil.rmtree(DATASET_ROOT / folder, ignore_errors=True)

    positives = list((DATASET_ROOT / "raw" / "medicine").glob("*.jpg"))
    negatives = list((DATASET_ROOT / "raw" / "not_medicine").glob("*.jpg"))

    samples = [(x, True) for x in positives] + [(x, False) for x in negatives]
    random.shuffle(samples)

    split = int(len(samples) * (1 - val_ratio))

    for name, data in [("train", samples[:split]), ("val", samples[split:])]:
        for image, medicine in data:
            img_out = DATASET_ROOT / "images" / name / image.name
            lbl_out = DATASET_ROOT / "labels" / name / f"{image.stem}.txt"
            img_out.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(image, img_out)
            lbl_out.parent.mkdir(parents=True, exist_ok=True)
            lbl_out.write_text("0 0.5 0.5 1.0 1.0\n" if medicine else "")

    yaml = DATASET_ROOT / "data.yaml"
    yaml.write_text(f"path: {DATASET_ROOT.as_posix()}\ntrain: images/train\nval: images/val\nnames:\n  0: medicine\n")
    return yaml

def train_model(dataset_yaml, base_model, epochs, image_size):
    import torch
    from ultralytics import YOLO

    cuda_available = torch.cuda.is_available()

    if cuda_available:
        device = 0
        gpu_name = torch.cuda.get_device_name(0)

        print(f"CUDA disponível: {gpu_name}")

        torch.cuda.empty_cache()
    else:
        device = "cpu"
        print("CUDA não disponível. Usando CPU.")

    model = YOLO(base_model)

    result = model.train(
        data=str(dataset_yaml),
        epochs=epochs,
        imgsz=image_size,
        # GPU
        device=device,
        # Reduz uso de VRAM
        batch=4,
        # Treinamento misto FP16 na GPU
        amp=cuda_available,
        # Evita problemas no Windows
        workers=2,
        # Não joga dataset inteiro na memória
        cache=False,
        project=str(API_ROOT / "runs" / "medicine_yolo"),
        name="train",
        exist_ok=True,
    )

    best = (Path(result.save_dir) / "weights" / "best.pt")

    MODEL_OUTPUT.parent.mkdir(parents=True,exist_ok=True)

    shutil.copy2(best,MODEL_OUTPUT)

    print(f"Modelo salvo: {MODEL_OUTPUT}")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epochs", type=int, default=50)
    parser.add_argument("--image-size", type=int, default=640)
    args = parser.parse_args()

    if not has_downloaded_images():
        collect_images(get_remedy_names(), 10, 100, 1)
    else:
        print("Imagens existentes encontradas. Reutilizando dataset.")

    yaml = prepare_dataset(0.2)
    train_model(yaml, DEFAULT_BASE_MODEL, args.epochs, args.image_size)


if __name__ == "__main__":
    main()
