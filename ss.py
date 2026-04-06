import requests
from flask import request, Response, send_file, jsonify, render_template
from pages import aiPage
import threading

class Flask_service:
    def __init__(self, API):
        self.API = API
        self.target_base_url = f"http://{self.API.config.API_IP}:{self.API.config.API_PORT}"
        self.lock = threading.Lock()

        # Raiz "/"
        @API.flask.route('/', methods=["GET", "POST"])
        def proxy_root():
            return render_template("index.html")

        # =========================
        # NF (porta 5002)
        # =========================
        @API.flask.route('/nf', methods=["POST"])
        def nf_service():
            url = f"http://{self.API.config.API_IP}:5002/nf"

            headers = dict(request.headers)
            headers.pop('Host', None)

            try:
                resp = requests.post(
                    url,
                    data=request.get_data(),
                    headers=headers,
                    timeout=10
                )
                return Response(resp.content, status=resp.status_code)
            except requests.exceptions.RequestException:
                return render_template("nonePage.html")

        # =========================
        # PILL (porta 5005) - PROXY DINÂMICO
        # =========================
        @API.flask.route('/pill', defaults={'path': ''}, methods=["GET", "POST", "PUT", "DELETE"])
        @API.flask.route('/pill/<path:path>', methods=["GET", "POST", "PUT", "DELETE"])
        def pill_service(path):
            base_url = f"http://{self.API.config.API_IP}:5005/pill"
            url = f"{base_url}/{path}" if path else base_url

            headers = dict(request.headers)
            headers.pop('Host', None)

            try:
                resp = requests.request(
                    method=request.method,
                    url=url,
                    headers=headers,
                    params=request.args,
                    data=request.get_data(),
                    timeout=10
                )

                return Response(
                    resp.content,
                    status=resp.status_code
                )

            except requests.exceptions.RequestException:
                return render_template("nonePage.html")

        # =========================
        # PROXY PADRÃO
        # =========================
        @API.flask.route('/pvec', methods=["GET", "POST"])
        def proxy_pvec():
            API.register.registerAccess(str(request.remote_addr), "PVEC", "")
            return self._proxy_request('/pvec')

        @API.flask.route('/inverterReceive', methods=["GET", "POST"])
        def proxy_inverter_receive():
            return self._proxy_request('/inverterReceive')

        # =========================
        # DOWNLOAD
        # =========================
        @API.flask.route('/download')
        def download_app():
            filepath = 'apps/CEESP_Solar.apk'
            API.register.registerAccess(str(request.remote_addr), "download", "")
            return send_file(filepath, as_attachment=True)

        # =========================
        # AI PAGE
        # =========================
        @API.flask.route('/ai')
        def ai_status():
            API.register.registerAccess(str(request.remote_addr), "AI Status", "")
            page = aiPage.getTestPage(self.API)
            return page

        # =========================
        # DADOS
        # =========================
        @API.flask.route('/homeData', methods=['GET'])
        @API.limiter.limit(API.config.FLASK_ACCESS_LIMIT)
        def homeDataRoute():
            API.register.registerAccess(str(request.remote_addr), "homeData", "")
            return jsonify(API.data.homeData)

        @API.flask.route('/structure', methods=['GET'])
        @API.limiter.limit(API.config.FLASK_ACCESS_LIMIT)
        def structureRoute():
            API.register.registerAccess(str(request.remote_addr), "structure", "")
            return jsonify(API.data.structureData)

        @API.flask.route('/structureInfo', methods=['GET'])
        @API.limiter.limit(API.config.FLASK_ACCESS_LIMIT)
        def structureInfoRoute():
            periodo = request.args.get('periodo', type=str)
            estrutura = request.args.get('estrutura', type=str)

            API.register.registerAccess(
                str(request.remote_addr),
                "structureInfo",
                f"{periodo}, {estrutura}"
            )

            if estrutura in ("A", "B", "C", "D") and periodo in ("dia", "semana", "mes"):
                return API.data.dataInfo[estrutura][periodo]

            return {'erro': 1}

        @API.flask.route('/paineis', methods=['GET'])
        @API.limiter.limit(API.config.FLASK_ACCESS_LIMIT)
        def paineisRoute():
            API.register.registerAccess(str(request.remote_addr), "paineis", "")
            return jsonify(API.data.paineisData)

        @API.flask.route('/painel', methods=['GET'])
        @API.limiter.limit(API.config.FLASK_ACCESS_LIMIT)
        def painelRoute():
            painel_id = request.args.get('painel', type=int)

            if painel_id is None:
                painel_id = -1

            API.register.registerAccess(
                str(request.remote_addr),
                "Painel",
                int(painel_id if 0 < painel_id <= 48 else -1)
            )

            return jsonify(API.data.getPanelInfo(painel_id))

        # =========================
        # Piranômetro
        # =========================
        @API.flask.route('/piranometro', methods=['GET'])
        def receiveRadiation():
            radiation = request.args.get('radiacao', type=float)

            API.register.registerAccess(
                str(request.remote_addr),
                "Piranometro",
                int(radiation) if radiation is not None else 0
            )

            return API.CEF.insert_radiation(radiation)

        # =========================
        # Clima
        # =========================
        @API.flask.route('/climatic', methods=['GET'])
        def climaticRoute():
            API.register.registerAccess(str(request.remote_addr), "Clima", "")
            return jsonify(API.data.climatic)

        # =========================
        # CEF
        # =========================
        @API.flask.route('/cef', methods=['GET'])
        def getCEF():
            API.register.registerAccess(str(request.remote_addr), "CEF Data", "")
            return jsonify(API.data.getCEF())

        # =========================
        # 404
        # =========================
        @API.flask.errorhandler(404)
        def page_not_found(e):
            API.register.registerAccess(str(request.remote_addr), "404", "")
            return render_template("nonePage.html"), 404

    # =========================
    # MÉTODO GENÉRICO DE PROXY
    # =========================
    def _proxy_request(self, path: str):
        url = f"{self.target_base_url}{path}"

        headers = dict(request.headers)
        headers.pop('Host', None)

        # Correção lógica
        if path in ('/pvec', '/structureInfo'):
            parameter = ""
        else:
            parameter = request.args.to_dict() if request.args else request.get_json(silent=True)

        if path not in ('/pvec', '/structureInfo'):
            self.API.register.registerAccess(
                str(request.remote_addr),
                path,
                parameter
            )

        try:
            resp = requests.request(
                method=request.method,
                url=url,
                headers=headers,
                params=request.args,
                json=request.get_json(silent=True),
                timeout=5
            )

            return Response(resp.content, status=resp.status_code)

        except requests.exceptions.Timeout:
            return render_template("nonePage.html")
        except requests.exceptions.RequestException:
            return render_template("nonePage.html")