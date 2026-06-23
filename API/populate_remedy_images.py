import argparse
import json
import mimetypes
import os
import re
import tempfile
import time
import urllib.parse
import urllib.request
from pathlib import Path
from urllib.error import HTTPError, URLError

from dotenv import load_dotenv
from PIL import Image


API_ROOT = Path(__file__).resolve().parent
USER_AGENT = (
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
    "AppleWebKit/537.36 Chrome/125 Safari/537.36"
)


def request_url(url, timeout=20, referer=None):
    headers = {"User-Agent": USER_AGENT, "Accept": "text/html,application/json,*/*"}
    if referer:
        headers["Referer"] = referer

    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def request_json(url, timeout=20):
    return json.loads(request_url(url, timeout=timeout).decode("utf-8"))


def duckduckgo_image_urls(query, max_results):
    search_url = "https://duckduckgo.com/?" + urllib.parse.urlencode(
        {"q": query, "iax": "images", "ia": "images"}
    )
    html = request_url(search_url).decode("utf-8", errors="ignore")
    match = re.search(r"vqd=['\"]?([^'\"&]+)", html)
    if not match:
        return []

    api_url = "https://duckduckgo.com/i.js?" + urllib.parse.urlencode(
        {"l": "br-pt", "o": "json", "q": query, "vqd": match.group(1)}
    )
    payload = json.loads(
        request_url(api_url, referer=search_url).decode("utf-8", errors="ignore")
    )
    return [
        item["image"]
        for item in payload.get("results", [])[:max_results]
        if item.get("image")
    ]


def search_image_urls(remedy_name, max_results):
    queries = [
        f"{remedy_name} medicamento caixa",
        f"{remedy_name} remedio embalagem",
        f"{remedy_name} bula caixa medicamento",
    ]

    urls = []
    seen = set()
    for query in queries:
        try:
            for url in duckduckgo_image_urls(query, max_results):
                if url not in seen:
                    seen.add(url)
                    urls.append(url)
                if len(urls) >= max_results:
                    return urls
        except Exception as error:
            print(f"Busca falhou para '{query}': {error}")

    return urls


def download_image(url, destination):
    try:
        destination.write_bytes(request_url(url, timeout=25))
        with Image.open(destination) as image:
            image.verify()
        with Image.open(destination) as image:
            rgb_image = image.convert("RGB")
            output = destination.with_suffix(".jpg")
            rgb_image.save(output, "JPEG", quality=90)

        if destination != output:
            destination.unlink(missing_ok=True)

        return output
    except Exception as error:
        print(f"Download ignorado ({url}): {error}")
        destination.unlink(missing_ok=True)
        destination.with_suffix(".jpg").unlink(missing_ok=True)
        return None


def multipart_body(field_name, file_path):
    boundary = f"----PillTimeBoundary{int(time.time() * 1000)}"
    filename = file_path.name
    content_type = mimetypes.guess_type(filename)[0] or "application/octet-stream"
    body = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="{field_name}"; filename="{filename}"\r\n'
        f"Content-Type: {content_type}\r\n\r\n"
    ).encode("utf-8")
    body += file_path.read_bytes()
    body += f"\r\n--{boundary}--\r\n".encode("utf-8")
    return body, boundary


def upload_image(api_base_url, remedy_id, file_path):
    query = urllib.parse.urlencode({"remedy": remedy_id})
    url = f"{api_base_url}/uploadImage?{query}"
    body, boundary = multipart_body("image", file_path)
    request = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "User-Agent": USER_AGENT,
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Content-Length": str(len(body)),
        },
    )

    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def image_count(api_base_url, remedy_id):
    query = urllib.parse.urlencode({"remedy": remedy_id})
    try:
        payload = request_json(f"{api_base_url}/image?{query}", timeout=15)
        return len(payload.get("images", []))
    except HTTPError as error:
        if error.code == 404:
            return 0
        raise


def wait_for_validation(api_base_url, remedy_id, previous_count, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        current_count = image_count(api_base_url, remedy_id)
        if current_count > previous_count:
            return current_count
        time.sleep(1)

    return previous_count


def get_remedies(api_base_url):
    payload = request_json(f"{api_base_url}/getRemedies")
    return [
        (str(remedy_id), remedy["name"])
        for remedy_id, remedy in payload.items()
        if remedy.get("name")
    ]


def normalize_api_base_url(value):
    return value.rstrip("/")


def build_default_api_url():
    load_dotenv(API_ROOT / "services" / ".env")
    load_dotenv(API_ROOT / ".env")
    port = os.getenv("FLASK_PORT", "5000")
    return f"http://200.18.75.25:8326"


def populate_remedy(api_base_url, remedy_id, remedy_name, target_images, search_limit, wait_timeout):
    current_count = image_count(api_base_url, remedy_id)
    if current_count >= target_images:
        print(f"{remedy_name}: ja possui {current_count} imagem(ns).")
        return

    missing = target_images - current_count
    print(f"{remedy_name}: buscando {missing} imagem(ns).")
    urls = search_image_urls(remedy_name, search_limit)

    with tempfile.TemporaryDirectory(prefix="pill_time_images_") as temp_dir:
        temp_path = Path(temp_dir)

        for index, url in enumerate(urls, start=1):
            if current_count >= target_images:
                break

            candidate = download_image(url, temp_path / f"{remedy_id}_{index}.download")
            if not candidate:
                continue

            try:
                upload_image(api_base_url, remedy_id, candidate)
                new_count = wait_for_validation(
                    api_base_url,
                    remedy_id,
                    current_count,
                    wait_timeout,
                )
                if new_count > current_count:
                    current_count = new_count
                    print(f"{remedy_name}: imagem aprovada ({current_count}/{target_images}).")
                else:
                    print(f"{remedy_name}: imagem rejeitada pelo validador.")
            except (HTTPError, URLError, TimeoutError) as error:
                print(f"{remedy_name}: falha ao enviar imagem: {error}")

    if current_count < target_images:
        print(f"{remedy_name}: finalizou com {current_count}/{target_images} imagem(ns).")


def main():
    parser = argparse.ArgumentParser(
        description="Busca imagens de remedios na internet e envia para validacao da API."
    )
    parser.add_argument("--api-url", default=build_default_api_url())
    parser.add_argument("--target-images", type=int, default=4)
    parser.add_argument("--search-limit", type=int, default=12)
    parser.add_argument("--wait-timeout", type=int, default=45)
    args = parser.parse_args()

    api_base_url = normalize_api_base_url(args.api_url)
    remedies = get_remedies(api_base_url)

    for remedy_id, remedy_name in remedies:
        populate_remedy(
            api_base_url=api_base_url,
            remedy_id=remedy_id,
            remedy_name=remedy_name,
            target_images=args.target_images,
            search_limit=args.search_limit,
            wait_timeout=args.wait_timeout,
        )


if __name__ == "__main__":
    main()
