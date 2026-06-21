import requests
import time
import statistics
import matplotlib.pyplot as plt

from concurrent.futures import ThreadPoolExecutor, as_completed


BASE_URL = "http://127.0.0.1:5000"


TEST_IMAGE = "test.jpg"

REMEDY_ID = "105"


REQUESTS_PER_TEST = 100


CONCURRENCY_LEVELS = [
    1,
    5,
    10,
    20,
    50
]


results = []

uploaded_filename = None



# ======================================================
# FUNÇÕES DAS ROTAS
# ======================================================


def upload_image():

    with open(TEST_IMAGE, "rb") as img:

        files = {
            "image": img
        }

        params = {
            "remedy": REMEDY_ID
        }


        return requests.post(
            f"{BASE_URL}/uploadImage",
            files=files,
            params=params,
            timeout=60
        )



def get_remedies():

    return requests.get(
        f"{BASE_URL}/getRemedies",
        timeout=30
    )



def get_images():

    return requests.get(
        f"{BASE_URL}/image",
        params={
            "remedy": REMEDY_ID
        },
        timeout=30
    )



def serve_image():

    return requests.get(
        f"{BASE_URL}/images/{uploaded_filename}",
        timeout=30
    )



# ======================================================
# EXECUÇÃO INDIVIDUAL
# ======================================================


def execute_request(function):

    start = time.perf_counter()

    try:

        response = function()

        status = response.status_code


        # captura filename do upload
        global uploaded_filename


        if (
            status == 200
            and "uploadImage" in function.__name__
        ):

            data = response.json()

            uploaded_filename = (
                data.get("filename")
            )


    except Exception as e:

        status = 0


    elapsed = (
        time.perf_counter()
        -
        start
    )


    return elapsed, status



# ======================================================
# TESTE DE CARGA
# ======================================================


def run_load_test(
        route,
        function,
        concurrency
):


    times = []

    errors = 0


    total_start = time.perf_counter()



    with ThreadPoolExecutor(
        max_workers=concurrency
    ) as executor:


        futures = []


        for _ in range(
            REQUESTS_PER_TEST
        ):


            futures.append(

                executor.submit(
                    execute_request,
                    function
                )

            )



        for future in as_completed(futures):

            elapsed, status = (
                future.result()
            )


            times.append(
                elapsed
            )


            if status != 200:
                errors += 1



    total_time = (
        time.perf_counter()
        -
        total_start
    )


    result = {


        "route":
            route,


        "concurrency":
            concurrency,


        "avg":
            statistics.mean(times),


        "p95":
            percentile(
                times,
                95
            ),


        "rps":
            REQUESTS_PER_TEST
            /
            total_time,


        "errors":
            errors

    }


    results.append(result)



    print(
        f"""
================================

ROTA:
{route}

CONCORRÊNCIA:
{concurrency}

Tempo médio:
{result['avg']:.4f}s

P95:
{result['p95']:.4f}s

RPS:
{result['rps']:.2f}

Erros:
{errors}

================================
"""
    )



# ======================================================
# PERCENTIL
# ======================================================


def percentile(values, p):

    values = sorted(values)

    index = int(
        len(values)
        *
        p
        /
        100
    )

    return values[index]



# ======================================================
# EXECUTA TODAS ROTAS
# ======================================================


def execute_tests():


    routes = [

        (
            "/uploadImage",
            upload_image
        ),


        (
            "/getRemedies",
            get_remedies
        ),


        (
            "/image",
            get_images
        ),


        (
            "/images/<filename>",
            serve_image
        )

    ]



    for route, function in routes:


        for concurrency in CONCURRENCY_LEVELS:


            run_load_test(
                route,
                function,
                concurrency
            )



# ======================================================
# GRÁFICOS
# ======================================================


def plot_results():


    routes = set(
        x["route"]
        for x in results
    )


    # ----------------------------
    # TEMPO
    # ----------------------------

    plt.figure(
        figsize=(10,6)
    )


    for route in routes:


        data = [

            x for x in results

            if x["route"] == route

        ]


        plt.plot(

            [
                x["concurrency"]
                for x in data
            ],

            [
                x["avg"]
                for x in data
            ],

            marker="o",

            label=route

        )



    plt.title(
        "Tempo médio de resposta"
    )

    plt.xlabel(
        "Usuários simultâneos"
    )

    plt.ylabel(
        "Tempo (segundos)"
    )


    plt.legend()

    plt.grid()



    # ----------------------------
    # RPS
    # ----------------------------


    plt.figure(
        figsize=(10,6)
    )


    for route in routes:


        data = [

            x for x in results

            if x["route"] == route

        ]



        plt.plot(

            [
                x["concurrency"]
                for x in data
            ],


            [
                x["rps"]
                for x in data
            ],


            marker="o",

            label=route

        )



    plt.title(
        "Capacidade da API"
    )


    plt.xlabel(
        "Usuários simultâneos"
    )


    plt.ylabel(
        "Requisições por segundo"
    )


    plt.legend()

    plt.grid()



    plt.show()



# ======================================================
# MAIN
# ======================================================


if __name__ == "__main__":


    print(
        "Iniciando benchmark da API..."
    )


    execute_tests()


    plot_results()


    print(
        "Teste finalizado"
    )