# Pill Time

Pill Time e um projeto composto por dois blocos principais:

- `pill_time/`: aplicativo Flutter usado pelo paciente para cadastrar remedios, horarios, imagens, alarmes e acompanhar pontuacao/progresso.
- `API/`: API Flask que fornece remedios, imagens e upload de imagens para o aplicativo.

O repositorio tambem possui scripts e arquivos auxiliares para popular a base de dados e documentacao do projeto.

## Estrutura Das Pastas

### `pill_time/`

Aplicativo Flutter.

Principais responsabilidades:

- Exibir e cadastrar remedios.
- Buscar remedios na API.
- Registrar horarios e alarmes.
- Mostrar tela de alarme e confirmacao de remedio tomado.
- Calcular progresso/pontuacao.
- Gerar PDF com informacoes cadastradas.

Arquivos importantes:

- `pill_time/lib/main.dart`: entrada do aplicativo.
- `pill_time/lib/src/providers/settings.dart`: configuracoes do app, incluindo IP e porta da API.
- `pill_time/lib/src/tools/connection.dart`: chamadas HTTP para a API.
- `pill_time/pubspec.yaml`: dependencias Flutter.

Por padrao, o app tenta acessar a API em:

```txt
http://200.18.75.25:8326
```

Esse IP/porta podem ser alterados dentro do proprio app pela tela de configuracoes.

### `API/`

API em Python com Flask.

Principais responsabilidades:

- `GET /getRemedies`: retorna os remedios cadastrados no banco.
- `GET /image?remedy=<id>`: retorna imagens de um remedio em base64.
- `GET /images/<filename>`: serve uma imagem diretamente.
- `POST /uploadImage?remedy=<id>`: recebe uma imagem, valida com YOLO e salva no banco apenas se for reconhecida como imagem de medicamento.

Arquivos importantes:

- `API/controller.py`: entrada da API.
- `API/services/flask_service.py`: rotas HTTP.
- `API/services/database.py`: acesso ao MySQL.
- `API/services/config.py`: leitura das variaveis de ambiente.
- `API/services/image_validator.py`: validacao de imagem com YOLO.
- `API/services/.env`: configuracoes locais da API.
- `API/dependencias.txt`: dependencias para instalar com `pip`.
- `API/sql.sql`: script de criacao das tabelas do banco.

### `Populate/`

Scripts auxiliares para popular dados/imagens no banco. O fluxo busca imagens, valida se parecem imagens de medicamento e envia para a API.

### `Dados/`

Arquivos de dados usados como base do projeto, como planilhas, CSV e PDF de medicamentos.

### `Docs/`

Documentos do projeto, como referencias, modelo de documentacao e diagramas.

### `images/` e `API/services/images/`

Pastas usadas para armazenar imagens salvas pela API. A pasta efetiva usada pela API depende da variavel `IMAGE_FOLDER` no `.env`.

## Como Inicializar A API

Os comandos abaixo consideram PowerShell no Windows.

### 1. Entrar na pasta da API

```powershell
cd "D:\Proj. Software\API"
```

### 2. Criar o ambiente virtual

```powershell
python -m venv .venv
```

### 3. Ativar o ambiente virtual

```powershell
.\.venv\Scripts\Activate.ps1
```

Se o PowerShell bloquear a ativacao por politica de execucao, rode:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

Quando o venv estiver ativo, o terminal deve mostrar `(.venv)` no inicio da linha.

### 4. Instalar as dependencias

```powershell
pip install -r dependencias.txt
```

Dependencias atuais:

```txt
flask
mysql-connector-python
python-dotenv
ultralytics
```

### 5. Conferir o arquivo `.env`

O arquivo fica em:

```txt
API/services/.env
```

Exemplo de configuracao:

```env
DB_PASSWORD="sua_senha"
DB_USER="pill"
DB_IP="ip"
DB_PORT=3406
DB_DATABASE="pill"
IMAGE_FOLDER="images"
YOLO_MODEL_PATH="models/medicine_yolo.pt"
YOLO_CONFIDENCE=0.45
YOLO_MEDICINE_CLASSES="medicine,medication,remedio,drug,pill,tablet,comprimido,capsule,capsula,blister,box,caixa,bottle"
FLASK_PORT=5000
```

Observacoes:

- O banco precisa estar acessivel com os dados configurados.
- O script de criacao das tabelas esta em `API/sql.sql`.
- `YOLO_MODEL_PATH` e relativo a raiz da pasta `API/` quando o caminho nao e absoluto.
- Com a configuracao acima, o modelo esperado fica em `API/models/medicine_yolo.pt`.
- Se o arquivo configurado nao existir, a API baixa e carrega o modelo padrao na raiz de `API/` antes de iniciar.
- O app Flutter esta configurado por padrao para acessar a porta `8326`. Para usar a API sem alterar o app, configure `FLASK_PORT=8326`; se mantiver `FLASK_PORT=5000`, ajuste a porta na tela de configuracoes do app.

### 6. Criar a pasta do modelo YOLO

Se for usar o caminho padrao:

```powershell
mkdir models
```

Coloque o arquivo do modelo treinado em:

```txt
API/models/medicine_yolo.pt
```

O modelo YOLO precisa ter classes compativeis com `YOLO_MEDICINE_CLASSES`. Se o seu modelo usa outros nomes de classe, ajuste essa variavel no `.env`.

### 7. Iniciar a API

Com o venv ativo e dentro da pasta `API/`, rode:

```powershell
python controller.py
```

A API vai iniciar na porta configurada em `FLASK_PORT`.

Exemplo:

```txt
http://localhost:5000
```

Para parar a API, use `Ctrl+C`.

## Como Inicializar O Aplicativo Flutter

### 1. Entrar na pasta do app

```powershell
cd "D:\Proj. Software\pill_time"
```

### 2. Baixar dependencias Flutter

```powershell
flutter pub get
```

### 3. Conferir dispositivos disponiveis

```powershell
flutter devices
```

### 4. Rodar o aplicativo

Para rodar no dispositivo padrao:

```powershell
flutter run
```

Para escolher um dispositivo especifico:

```powershell
flutter run -d <id_do_dispositivo>
```

Exemplo para Android conectado:

```powershell
flutter run -d RQCX600YYCV
```

### 5. Gerar APK de debug

```powershell
flutter build apk --debug
```

O APK sera gerado em:

```txt
pill_time/build/app/outputs/flutter-apk/app-debug.apk
```

## Conectando App E API

Para o app acessar a API:

1. A API deve estar rodando.
2. O celular/emulador deve conseguir acessar o IP e a porta da API.
3. No app, confira a tela de configuracoes e ajuste IP/porta se necessario.

Exemplos comuns:

- API rodando em uma maquina da rede: use o IP da maquina, por exemplo `192.168.0.10`.
- API em servidor externo: use o IP/dominio do servidor e a porta configurada.
- Emulador Android acessando API local na mesma maquina: normalmente pode ser necessario usar `10.0.2.2` em vez de `localhost`.

## Banco De Dados

A API usa MySQL. O script base esta em:

```txt
API/sql.sql
```

Ele cria:

- `RemedyType`
- `Remedy`
- `Dosage`
- `Remedy_Dosage`
- `Image`

Depois de criar as tabelas, confira se o `.env` aponta para o banco correto.

## Fluxo De Upload De Imagem

1. O app ou script envia uma imagem para `POST /uploadImage?remedy=<id>`.
2. A API salva temporariamente a imagem na pasta configurada.
3. `image_validator.py` carrega o modelo YOLO.
4. Se o YOLO detectar uma classe aceita, a imagem e mantida e salva no banco.
5. Se nao detectar, a imagem e removida e o banco nao e alterado.

Resposta de sucesso:

```json
{
  "status": "success",
  "filename": "1.jpg",
  "medicine_image": true
}
```

Resposta quando a imagem nao e reconhecida como medicamento:

```json
{
  "status": "error",
  "message": "Image is not recognized as a medicine image"
}
```

## Treinar Modelo YOLO De Medicamentos

A API possui um script para buscar os remedios cadastrados no banco, baixar imagens de caixas de remedio via busca de imagens e treinar um YOLO para detectar a classe `medicine`.

Com o venv ativo e dentro da pasta `API/`, rode:

```powershell
python train_medicine_yolo.py
```

O script cria o dataset em:

```txt
API/datasets/medicine_yolo
```

E copia o melhor modelo treinado para:

```txt
API/models/medicine_yolo.pt
```

Para reutilizar imagens ja baixadas sem buscar novamente:

```powershell
python train_medicine_yolo.py --skip-download
```

## Comandos Uteis

### API

```powershell
cd "D:\Proj. Software\API"
.\.venv\Scripts\Activate.ps1
python controller.py
```

### App

```powershell
cd "D:\Proj. Software\pill_time"
flutter pub get
flutter run
```

### Testar build Android

```powershell
cd "D:\Proj. Software\pill_time"
flutter build apk --debug
```

## Observacoes

- Nao envie arquivos sensiveis como senhas reais em `.env` para repositorios publicos.
- O app usa permissao de notificacao, alarmes e servico em primeiro plano no Android.
- O validador YOLO depende de um modelo treinado para reconhecer medicamentos; `ultralytics` sozinho nao garante que um modelo generico detecte caixas de remedio corretamente.
