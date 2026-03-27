from services.database import Database

database = Database(
    db_name='pill',
    ip='200.18.75.25',
    password='',
    port=8324,
    user='pill'
)

# print(database.getRemedy(105))

print(database.getRemedyImages(id_remedy=105))

# print(database.getAllRemedies())


