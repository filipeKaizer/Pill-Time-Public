import mysql.connector

class Database:
    def __init__(self, db_name, user, password, port, ip):
        self.name = db_name
        self.user = user
        self.password = password
        self.port = port
        self.ip = ip
        

    def getRemedy(self, id_remedy):
        json = {}

        try:
            conn = self.new_connection()

            if conn is not None:
                cursor = conn.cursor()

                query = """
                    SELECT 
                        r.remedy_name,
                        r.remedy_use,
                        t.type_name,
                        d.dose
                    FROM Remedy r
                    JOIN RemedyType t ON r.id_type = t.id_type
                    LEFT JOIN Remedy_Dosage rd ON r.id_remedy = rd.id_remedy
                    LEFT JOIN Dosage d ON rd.id_dosage = d.id_dosage
                    WHERE r.id_remedy = %s;
                """

                cursor.execute(query, (id_remedy,))
                results = cursor.fetchall()

                if not results:
                    return None

                # dados fixos (vem repetido, pega só o primeiro)
                json['name'] = results[0][0]
                json['use'] = results[0][1]
                json['type'] = results[0][2]

                # doses (pode ter várias linhas)
                doses = [row[3] for row in results if row[3] is not None]

                json['doses'] = doses

                cursor.close()
                conn.close()

                return json

        except Exception as e:
            print("Erro:", e)
            return None
        
    def getRemedyImages(self, id_remedy):
        '''
        Obtem os ids das imagens de um determinado remédio
        '''
        images = []

        try:
            conn = self.new_connection()

            if conn is not None:
                cursor = conn.cursor()

                query = """
                    SELECT image_path 
                    FROM Image 
                    WHERE id_remedy = %s
                    ORDER BY id_image DESC
                    LIMIT 4
                """
                print("Id", id_remedy)
                cursor.execute(query, (int(id_remedy),))

                results = cursor.fetchall()

                images = [row[0] for row in results]

                return images
        except Exception as e:
            print(e)
        
        return None

    def get_next_image_id(self):
        '''
        Obtem o id da nova imagem
        '''
        try:
            conn = self.new_connection()

            if conn is not None:
                cursor = conn.cursor()

                query = """
                    SELECT MAX(id_image) from Image
                """

                cursor.execute(query)

                result = cursor.fetchone()

                conn.commit()

                cursor.close()
                conn.close()

                return int(result[0]) + 1 if result and result[0] else 0
        
        except Exception as e:
            print(e)
        
        return None

    def save_image_id(self, remedy_id, image_path):
        """
        Salva uma imagem
        """
        try:
            conn = self.new_connection()

            if conn is not None:
                cursor = conn.cursor()

                query = """
                    INSERT INTO Image (id_remedy, image_path) VALUES (%s, %s)
                """

                cursor.execute(query, (remedy_id, image_path,))

                id = cursor.lastrowid
                
                conn.commit()

                cursor.close()
                conn.close()

                return id
        except Exception as e:
            print(e)
        
        return None

    def getAllRemedies(self):
            '''
            Obtem e retorna um JSON com todos os remédios
            '''
            json = {}

            try:
                conn = self.new_connection()

                if conn is not None:
                    cursor = conn.cursor()

                    query = """
                        SELECT 
                            r.id_remedy,
                            r.remedy_name,
                            r.remedy_use,
                            t.type_name,
                            d.dose
                        FROM Remedy r
                        JOIN RemedyType t ON r.id_type = t.id_type
                        LEFT JOIN Remedy_Dosage rd ON r.id_remedy = rd.id_remedy
                        LEFT JOIN Dosage d ON rd.id_dosage = d.id_dosage
                        ORDER BY r.id_remedy
                    """

                    cursor.execute(query)
                    results = cursor.fetchall()

                    for result in results:
                        id_remedy = result[0]
                        name = result[1]
                        use = result[2]
                        type_name = result[3]
                        dose = result[4]

                        # Se ainda não existe no JSON, cria
                        if id_remedy not in json:
                            json[id_remedy] = {
                                'name': name,
                                'use': use,
                                'type': type_name,
                                'dose': []
                            }

                        # Adiciona a dose se não for nula
                        if dose is not None:
                            json[id_remedy]['dose'].append(dose)

            except Exception as e:
                print(e)

            return json

    def new_connection(self):
        '''
        Cria uma nova conexão com a base de dados
        '''
        try:
            conn = mysql.connector.connect(
                host=self.ip,
                user=self.user,
                password=self.password,
                database=self.name,
                port=self.port
            )        
            return conn
        except Exception as e:
            print(e)
            return None
