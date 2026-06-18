import argparse
import json
import os
import random
import re
import shutil
import time
import urllib.parse
import urllib.request
from urllib.error import HTTPError, URLError
from pathlib import Path

from dotenv import load_dotenv
from PIL import Image
from services.config import Config
from services.database import Database


API_ROOT = Path(__file__).resolve().parent
DATASET_ROOT = API_ROOT / "datasets" / "medicine_yolo"
MODEL_OUTPUT = API_ROOT / "models" / "medicine_yolo.pt"
DEFAULT_BASE_MODEL = "yolo26n.pt"
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/125.0 Safari/537.36"
)

NEGATIVE_QUERIES = [
    "caixa de cereal produto",
    "caixa de sapato produto",
    "embalagem de brinquedo",
    "caixa de celular produto",
    "embalagem de alimento supermercado",
]


def request_url(url, *, timeout=20, referer=None):
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/json,*/*",
        "Accept-Language": "pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7",
    }
    if referer:
        headers["Referer"] = referer

    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def duckduckgo_image_urls(query, max_results):
    search_url = "https://duckduckgo.com/?" + urllib.parse.urlencode(
        {"q": query, "iax": "images", "ia": "images"}
    )
    html = request_url(search_url).decode("utf-8", errors="ignore")
    match = re.search(r"vqd=['\"]?([^'\"&]+)", html)
    if not match:
        raise RuntimeError(f"Nao foi possivel obter token de busca para: {query}")

    params = {
        "l": "br-pt",
        "o": "json",
        "q": query,
        "vqd": match.group(1),
        "f": ",,,",
        "p": "1",
    }
    api_url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode(params)
    payload = json.loads(
        request_url(api_url, referer=search_url).decode("utf-8", errors="ignore")
    )

    urls = []
    for item in payload.get("results", []):
        image_url = item.get("image")
        if image_url:
            urls.append(image_url)
        if len(urls) >= max_results:
            break

    return urls


def bing_image_urls(query, max_results):
    search_url = "https://www.bing.com/images/search?" + urllib.parse.urlencode(
        {"q": query, "form": "HDRSC2", "first": "1"}
    )
    html = request_url(search_url).decode("utf-8", errors="ignore")
    urls = []

    for match in re.finditer(r"murl&quot;:&quot;(.*?)&quot;", html):
        image_url = match.group(1).replace("\\/", "/")
        image_url = image_url.encode("utf-8").decode("unicode_escape")
        if image_url and image_url not in urls:
            urls.append(image_url)
        if len(urls) >= max_results:
            break

    return urls


def search_image_urls(query, max_results):
    engines = [
        ("DuckDuckGo", duckduckgo_image_urls),
        ("Bing", bing_image_urls),
    ]

    for engine_name, engine in engines:
        try:
            urls = engine(query, max_results)
            if urls:
                return urls
            print(f"{engine_name} nao retornou imagens para: {query}")
        except (HTTPError, URLError, TimeoutError, json.JSONDecodeError) as e:
            print(f"{engine_name} falhou para '{query}': {e}")

    return []


def safe_filename(value):
    value = re.sub(r"[^a-zA-Z0-9_-]+", "_", value.strip().lower())
    return value.strip("_") or "image"


def download_image(url, destination):
    try:
        data = request_url(url)
        destination.write_bytes(data)

        with Image.open(destination) as image:
            image.verify()

        with Image.open(destination) as image:
            rgb_image = image.convert("RGB")
            rgb_image.save(destination.with_suffix(".jpg"), "JPEG", quality=90)

        if destination.suffix.lower() != ".jpg":
            destination.unlink(missing_ok=True)

        return destination.with_suffix(".jpg")
    except Exception:
        destination.unlink(missing_ok=True)
        destination.with_suffix(".jpg").unlink(missing_ok=True)
        return None


def get_remedy_names():
    env_path = API_ROOT / "services" / ".env"
    load_dotenv(env_path)

    config = Config()
    database = Database(
        db_name=config.db_database,
        user=config.db_user,
        password=config.db_password,
        ip=config.db_ip,
        port=config.db_port,
    )

    remedies = database.getAllRemedies()
    return sorted({remedy["name"] for remedy in remedies.values() if remedy.get("name")})


def collect_images(names, images_per_remedy, negative_images, pause_seconds):
    raw_positive = DATASET_ROOT / "raw" / "medicine"
    raw_negative = DATASET_ROOT / "raw" / "not_medicine"
    raw_positive.mkdir(parents=True, exist_ok=True)
    raw_negative.mkdir(parents=True, exist_ok=True)

    positive_count = 0
    for name in names:
        query = f"{name} caixa medicamento"
        print(f"Buscando imagens: {query}")
        urls = search_image_urls(query, images_per_remedy * 2)

        saved_for_name = 0
        for index, url in enumerate(urls):
            if saved_for_name >= images_per_remedy:
                break

            filename = f"{safe_filename(name)}_{index}.jpg"
            saved = download_image(url, raw_positive / filename)
            if saved:
                saved_for_name += 1
                positive_count += 1

        time.sleep(pause_seconds)

    negative_count = 0
    per_query = max(1, negative_images // len(NEGATIVE_QUERIES))
    for query in NEGATIVE_QUERIES:
        print(f"Buscando negativos: {query}")
        urls = search_image_urls(query, per_query * 2)

        saved_for_query = 0
        for index, url in enumerate(urls):
            if saved_for_query >= per_query:
                break

            filename = f"{safe_filename(query)}_{index}.jpg"
            saved = download_image(url, raw_negative / filename)
            if saved:
                saved_for_query += 1
                negative_count += 1

        time.sleep(pause_seconds)

    print(f"Imagens positivas: {positive_count}")
    print(f"Imagens negativas: {negative_count}")


def reset_prepared_dataset():
    for folder in ["images", "labels"]:
        path = DATASET_ROOT / folder
        if path.exists():
            shutil.rmtree(path)


def write_label(label_path, is_medicine):
    label_path.parent.mkdir(parents=True, exist_ok=True)
    if is_medicine:
        label_path.write_text("0 0.5 0.5 1.0 1.0\n", encoding="utf-8")
    else:
        label_path.write_text("", encoding="utf-8")


def prepare_dataset(val_ratio):
    reset_prepared_dataset()

    positive_images = list((DATASET_ROOT / "raw" / "medicine").glob("*.jpg"))
    negative_images = list((DATASET_ROOT / "raw" / "not_medicine").glob("*.jpg"))
    samples = [(path, True) for path in positive_images]
    samples.extend((path, False) for path in negative_images)
    random.shuffle(samples)

    if not positive_images:
        raise RuntimeError("Nenhuma imagem positiva encontrada para treinar.")

    split_index = max(1, int(len(samples) * (1 - val_ratio)))
    splits = {
        "train": samples[:split_index],
        "val": samples[split_index:] or samples[:1],
    }

    for split_name, split_samples in splits.items():
        for source, is_medicine in split_samples:
            target_image = DATASET_ROOT / "images" / split_name / source.name
            target_label = DATASET_ROOT / "labels" / split_name / f"{source.stem}.txt"
            target_image.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target_image)
            write_label(target_label, is_medicine)

    dataset_yaml = DATASET_ROOT / "data.yaml"
    dataset_yaml.write_text(
        "\n".join(
            [
                f"path: {DATASET_ROOT.as_posix()}",
                "train: images/train",
                "val: images/val",
                "names:",
                "  0: medicine",
                "",
            ]
        ),
        encoding="utf-8",
    )
    return dataset_yaml


def train_model(dataset_yaml, base_model, epochs, image_size):
    from ultralytics import YOLO

    MODEL_OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    model = YOLO(base_model)
    results = model.train(
        data=str(dataset_yaml),
        epochs=epochs,
        imgsz=image_size,
        project=str(API_ROOT / "runs" / "medicine_yolo"),
        name="train",
        exist_ok=True,
    )

    best_model = Path(results.save_dir) / "weights" / "best.pt"
    shutil.copy2(best_model, MODEL_OUTPUT)
    print(f"Modelo treinado copiado para: {MODEL_OUTPUT}")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Baixa imagens de caixas de remedios e treina um YOLO."
    )
    parser.add_argument("--images-per-remedy", type=int, default=8)
    parser.add_argument("--negative-images", type=int, default=80)
    parser.add_argument("--epochs", type=int, default=50)
    parser.add_argument("--image-size", type=int, default=640)
    parser.add_argument("--base-model", default=DEFAULT_BASE_MODEL)
    parser.add_argument("--val-ratio", type=float, default=0.2)
    parser.add_argument("--pause-seconds", type=float, default=1.0)
    parser.add_argument(
        "--skip-download",
        action="store_true",
        help="Usa imagens ja baixadas em datasets/medicine_yolo/raw.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if not args.skip_download:
        remedy_names = get_remedy_names()
        if not remedy_names:
            raise RuntimeError("Nenhum remedio encontrado no banco.")

        print(f"Remedios encontrados: {len(remedy_names)}")
        collect_images(
            remedy_names,
            args.images_per_remedy,
            args.negative_images,
            args.pause_seconds,
        )

    dataset_yaml = prepare_dataset(args.val_ratio)
    train_model(dataset_yaml, args.base_model, args.epochs, args.image_size)


if __name__ == "__main__":
    main()
