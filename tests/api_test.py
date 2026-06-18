import requests
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from statistics import mean
import matplotlib.pyplot as plt

BASE_URL = "http://127.0.0.1:5000"

NUM_REQUESTS = 200
CONCURRENCY = 20

TEST_IMAGE_PATH = "test.jpg"
REMEDY_NAME = "teste_remedio"


# =========================
# ARMAZENAMENTO GLOBAL DE MÉTRICAS
# =========================
metrics = {
    "routes": [],
    "avg_time": [],
    "rps": []
}


def time_request(func, *args, **kwargs):
    start = time.perf_counter()
    response = func(*args, **kwargs)
    elapsed = time.perf_counter() - start
    return response, elapsed


def run_test(route_name, task_func):
    times = []

    with ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = [executor.submit(task_func) for _ in range(NUM_REQUESTS)]

        for f in as_completed(futures):
            _, t = f.result()
            times.append(t)

    avg_time = mean(times)
    rps = NUM_REQUESTS / sum(times)

    print(f"\n=== {route_name} ===")
    print("Tempo médio:", avg_time)
    print("RPS:", rps)

    metrics["routes"].append(route_name)
    metrics["avg_time"].append(avg_time)
    metrics["rps"].append(rps)


# =========================
# TESTES
# =========================
def test_get_remedies():
    def task():
        return time_request(requests.get, f"{BASE_URL}/getRemedies")

    run_test("/getRemedies", task)


def test_get_images():
    def task():
        return time_request(
            requests.get,
            f"{BASE_URL}/image",
            params={"remedy": REMEDY_NAME},
        )

    run_test("/image", task)


def test_serve_image(filename):
    def task():
        return time_request(requests.get, f"{BASE_URL}/images/{filename}")

    run_test("/images/<filename>", task)


def test_upload_image():
    uploaded_filename = None

    def task():
        nonlocal uploaded_filename

        with open(TEST_IMAGE_PATH, "rb") as img:
            files = {"image": img}
            params = {"remedy": REMEDY_NAME}

            r, t = time_request(
                requests.post,
                f"{BASE_URL}/uploadImage",
                files=files,
                params=params,
            )

        if r.status_code == 200 and uploaded_filename is None:
            try:
                uploaded_filename = r.json().get("filename")
            except:
                pass

        return r.status_code, t

    run_test("/uploadImage", task)

    return uploaded_filename


# =========================
# PLOTS
# =========================
def plot_results():
    # Tempo médio
    plt.figure()
    plt.bar(metrics["routes"], metrics["avg_time"])
    plt.title("Tempo médio de resposta por rota")
    plt.ylabel("Segundos")
    plt.xlabel("Rotas")
    plt.xticks(rotation=30)

    # RPS
    plt.figure()
    plt.bar(metrics["routes"], metrics["rps"])
    plt.title("Requisições por segundo (RPS) por rota")
    plt.ylabel("RPS")
    plt.xlabel("Rotas")
    plt.xticks(rotation=30)

    plt.show()


# =========================
# MAIN
# =========================
if __name__ == "__main__":
    print("Iniciando testes de carga...\n")

    uploaded_file = test_upload_image()
    test_get_remedies()
    test_get_images()

    if uploaded_file:
        test_serve_image(uploaded_file)

    plot_results()

    print("\nTestes finalizados.")