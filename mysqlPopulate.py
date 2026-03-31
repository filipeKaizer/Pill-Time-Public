import pandas as pd
import mysql.connector
import re

# 🔌 CONFIGURAÇÃO DO BANCO
conn = mysql.connector.connect(
    host="200.18.75.25",
    user="pill",
    password="***",
    database="pill",
    port=8324
)

cursor = conn.cursor()

# 📂 CARREGAR EXCEL
df = pd.read_excel("medicamentos.xlsx")

# 🔁 CACHE
type_cache = {}
dosage_cache = {}
remedy_cache = {}

# =========================
# TIPO
# =========================
def get_or_create_type(type_name):
    type_name = str(type_name).strip().lower()

    if type_name in type_cache:
        return type_cache[type_name]

    cursor.execute(
        "SELECT id_type FROM RemedyType WHERE type_name = %s",
        (type_name,)
    )
    result = cursor.fetchone()

    if result:
        type_id = result[0]
    else:
        cursor.execute(
            "INSERT INTO RemedyType (type_name) VALUES (%s)",
            (type_name,)
        )
        type_id = cursor.lastrowid

    type_cache[type_name] = type_id
    return type_id


# =========================
# DOSAGEM
# =========================
def normalize_dose(dose_str):
    if not dose_str:
        return None

    match = re.search(r"[\d\.,]+", str(dose_str))
    if not match:
        return None

    value = match.group()
    value = value.replace(".", "")
    value = value.replace(",", ".")

    try:
        return float(value)
    except:
        return None


def get_or_create_dosage(dose_value):
    if dose_value in dosage_cache:
        return dosage_cache[dose_value]

    cursor.execute(
        "SELECT id_dosage FROM Dosage WHERE dose = %s",
        (dose_value,)
    )
    result = cursor.fetchone()

    if result:
        dosage_id = result[0]
    else:
        cursor.execute(
            "INSERT INTO Dosage (dose) VALUES (%s)",
            (dose_value,)
        )
        dosage_id = cursor.lastrowid

    dosage_cache[dose_value] = dosage_id
    return dosage_id


# =========================
# REMEDIO
# =========================
def get_or_create_remedy(nome, type_id, uso):
    nome = str(nome).strip().lower()
    uso = str(uso).strip().lower()

    if nome in remedy_cache:
        return remedy_cache[nome]

    cursor.execute(
        "SELECT id_remedy FROM Remedy WHERE remedy_name = %s",
        (nome,)
    )
    result = cursor.fetchone()

    if result:
        remedy_id = result[0]
    else:
        cursor.execute("""
            INSERT INTO Remedy (remedy_name, id_type, remedy_use)
            VALUES (%s, %s, %s)
        """, (nome, type_id, uso))
        remedy_id = cursor.lastrowid

    remedy_cache[nome] = remedy_id
    return remedy_id


# =========================
# INSERÇÃO
# =========================
for _, row in df.iterrows():
    nome = row["nome"]
    tipo = row["tipo"]
    uso = row["uso"]
    doses = row["doses"]

    if pd.isna(nome) or pd.isna(tipo) or pd.isna(uso):
        continue

    # tipo
    type_id = get_or_create_type(tipo)

    # remédio
    remedy_id = get_or_create_remedy(nome, type_id, uso)

    # =========================
    # DOSES (N:N)
    # =========================
    if pd.notna(doses):
        dose_list = str(doses).split(",")

        for d in dose_list:
            dose_value = normalize_dose(d)

            if dose_value is None:
                continue

            dosage_id = get_or_create_dosage(dose_value)

            # INSERT IGNORE evita duplicação automaticamente
            cursor.execute("""
                INSERT IGNORE INTO Remedy_Dosage (id_remedy, id_dosage)
                VALUES (%s, %s)
            """, (remedy_id, dosage_id))


# 💾 SALVAR UMA VEZ (muito mais rápido)
conn.commit()

# 🔒 FECHAR
cursor.close()
conn.close()

print("✅ Dados inseridos com sucesso (otimizado)!")