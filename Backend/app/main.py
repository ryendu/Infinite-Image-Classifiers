import tensorflow as tf
from tensorflow import keras
import numpy as np
import pandas as pd 
import firebase_admin as admin 
from firebase_admin import firestore, storage, messaging
import datetime
import requests
import csv
import uuid
from io import StringIO
from flask_restful import Api, Resource
from flask import Flask, request
import time, sched
from sklearn.model_selection import train_test_split
import traceback
from syncer import sync
import threading
import coremltools
import os
import json
from MainTrainer import MainTrainer
from tensorflow.python.keras.applications.densenet import preprocess_input
import HelperFunctions
import MLTrainers as mlt
from urllib.request import urlopen
from PIL import Image
import requests
from io import StringIO



app = Flask(__name__)
api = Api(app)
if HelperFunctions.DEVELOPMENT:
    cred = admin.credentials.Certificate("app/AdminServiceAccountKey.json")
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'app/serviceAccountKey.json'
else:
    cred = admin.credentials.Certificate("AdminServiceAccountKey.json")
    os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'serviceAccountKey.json'

admin.initialize_app(cred, {
    'storageBucket': 'aiologyapp.appspot.com'
})
db = firestore.client()
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'


@app.route("/")
def hello():
    return "Welcome to Aiology ML Training. Access the correct endpoint to request Training."
class AiologyTrainingServer(Resource):
    def get(self):
        args = request.args
        print (args) # For debugging
        id = args.to_dict().get("id")
        training_models_ref = db.collection("TrainingModels").document(id)
        doc_data = training_models_ref.get().to_dict()
        if not HelperFunctions.DEVELOPMENT:
            task = threading.Thread(target=self.carry_out_task,args=(doc_data,training_models_ref,id))
            task.start()
        else:
            self.carry_out_task(doc_data,training_models_ref,id)
        return {"status":"sucessful"}

    def carry_out_task(self, doc_data, training_models_ref, id):
        training_mlmodel = MainTrainer(id=id,doc_data=doc_data)
        if doc_data.get("userRequestedTask") == "BeginTraining":
            training_mlmodel.begin_training()
            if HelperFunctions.DEVELOPMENT == False:
                training_models_ref.update({"userRequestedTask":""})
        

api.add_resource(AiologyTrainingServer, "/aiologyTrainingServer",endpoint="train")
if __name__ == "__main__":
    if HelperFunctions.DEVELOPMENT:
        app.run(host ='0.0.0.0', port = 5000, debug=True)
    else:
        app.run(host ='0.0.0.0',debug=False)



