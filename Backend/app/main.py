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
from tensorflow.python.keras.applications.densenet import preprocess_input
from urllib.request import urlopen
from PIL import Image
import requests
from io import StringIO



app = Flask(__name__)
api = Api(app)
DEVELOPMENT = True
if DEVELOPMENT:
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
class InfiniteImageClassifiers(Resource):
    def get(self):
        self.db = firestore.client()
        args = request.args
        self.id = args.to_dict().get("id")
        self.training_models_ref = self.db.collection("TrainingModels").document(self.id)
        self.doc_data = self.training_models_ref.get().to_dict()
        
        if not DEVELOPMENT:
            task = threading.Thread(target=self.begin_training,args=())
            task.start()
        else:
            #self.doc_data,self.training_models_ref,id
            self.begin_training()
        return {"status":"sucessful"}

    def update_status(self, contents):
        training_models_ref = self.db.collection("TrainingModels").document(self.id)
        training_models_ref.update({"status":contents})

    def update_progress(self,progress):
        training_models_ref = self.db.collection("TrainingModels").document(self.id)
        training_models_ref.update({"progress":progress})

    def update_train_stats(self,accuracy, loss):
        training_models_ref = self.db.collection("TrainingModels").document(self.id)
        training_models_ref.update({"accuracy":accuracy,"loss":loss})

    def update_model_paths(self, mlmodel_path,uuid):
        training_models_ref = self.db.collection("TrainingModels").document(self.id)
        training_models_ref.update({"mlmodelPath":mlmodel_path,"modelStorageUUID":uuid})

    
    def get_dataset(self):
        blob = storage.bucket().blob('Datasets/{}'.format(self.doc_data.get("datasetPath")))
        print("Dataset path: {}".format(self.doc_data.get("datasetPath")))
        download_path = blob.generate_signed_url(datetime.timedelta(seconds=5000), method='GET')
        print(download_path)
        downloaded_file = requests.get(download_path)
        df = pd.read_csv(download_path)
        return df

    def begin_training(self): 
        self.refresh_data()
        self.distribute_to_train()

    def refresh_data(self):
        user_ref = self.db.collection("Users").document(self.doc_data.get("user"))
        self.user_data = user_ref.get().to_dict()
        self.update_progress(0.01)

        
    def finished_and_upload(self, model,mlmodel_converter):
        self.update_progress(0.97)
        self.update_status("Training Ended")
        uuid = ""
        if self.doc_data.get("modelStorageUUID") != None and self.doc_data.get("modelStorageUUID") != "" and type(self.doc_data.get("modelStorageUUID")) == str:
            uuid = self.doc_data.get("modelStorageUUID")
            print("got renewed uuid: {}".format(uuid))
        else:
            uuid = self.get_uuid()
            print("Got new UUID {}".format(uuid))
            
        mlmodel_model_path = uuid + ".mlmodel"
        mlmodel_model = mlmodel_converter()
        mlmodel_model.author = self.user_data.get("firstName") + " " + self.user_data.get("lastName")
        mlmodel_model.short_description = self.doc_data.get("name")
        mlmodel_model.save("tmp/finishedModels/" + mlmodel_model_path)
        self.update_progress(0.98)
        self.upload_model(mlmodel_model_path)
        self.update_model_paths( mlmodel_model_path, uuid)
        self.update_progress(1)
        self.update_status("Finished!")

    def get_uuid(self):
        return str(uuid.uuid4())

    def upload_model(self,mlmodel_uuid):
        self.update_status("Uploading Finished Model")
        mlmodel_blob = storage.bucket().blob('CompletedModels/{}'.format(mlmodel_uuid))

        with open("tmp/finishedModels/{}".format(mlmodel_uuid),mode="rb") as mlmodelFile:
            mlmodel_blob.upload_from_file(mlmodelFile)

        os.remove("tmp/finishedModels/{}".format(mlmodel_uuid))


    def distribute_to_train(self):
        from Trainers import ImageClassifierTrainer as ict
        trainer = ict(parent=self)
        trainer.train_vanilla_image_classifier()


        

api.add_resource(InfiniteImageClassifiers, "/trainImageClassifier",endpoint="train")
if __name__ == "__main__":
    if DEVELOPMENT:
        app.run(host ='0.0.0.0', port = 5000, debug=True)
    else:
        app.run(host ='0.0.0.0',debug=False)



