# -*- coding: utf-8 -*-
from pymongo import MongoClient
import time
client = MongoClient(
    "mongodb://59.11.230.189:27017,59.11.230.235:27017,175.214.6.71:27017/?replicaSet=rs0"
)


db = client["repl_test"]
collection = db["dbs"]

while(True):
    print("Connected Server:", client.primary)
    documents = collection.find()
    for doc in documents:
           print(doc)

    time.sleep(5)

