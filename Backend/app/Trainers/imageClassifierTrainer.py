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
from sklearn.model_selection import train_test_split

class ImageClassifierTrainer():
    
    def __init__(self, parent):
        self.parent = parent
        self.db = firestore.client()

    def train_vanilla_image_classifier(self):
        trainingDataUUID = self.parent.doc_data.get("trainingDatasetUUID")
        self.trainingDataRatio = self.parent.doc_data.get("trainingDataRatio")
        
        self.total_epochs = self.parent.doc_data.get("epochs")
        self.frozen_epochs = self.parent.doc_data.get("frozenEpochs")
        #also doubles as key to decoding output
        self.img_classes = self.parent.doc_data.get("classes")

        #get data
        folder = 'Datasets/ImageClassifierDatasets/{}/'.format(trainingDataUUID)
        class_dirs = list_sub_directories(path=folder)
        x = []
        y = []
        for dir in class_dirs:
            #list all items
            print("NEW CLASS GOT {}__________________________________________________".format(dir))
            objs = list_objects_in_dir(dir, storage.bucket())
            for obj in objs:
                download_path = obj.generate_signed_url(datetime.timedelta(seconds=5000), method='GET')
                img = Image.open(urlopen(download_path))
                x.append(np.array(img))
                pth = obj.name.split('/')[-2]
                y.append(pth)

        y = [self.img_classes.index(a) for a in y]
        y = np.array(y)

        size = (299, 299) 
        x = ([keras.preprocessing.image.smart_resize(img, size) for img in x])
        x = np.array(x)
        # batch_size = len(x) / 4
        # if len(x) > 32 and len(x) > 0:
        #     batch_size = len(x)/4
        # elif len(x) > 64 and len(x) > 0:
        #     batch_size = len(x)/8
        # elif len(x) <= 32:
        #     batch_size = len(x)/2
        # batch_size = 2

        #Preprocessing
        train_datagen = keras.preprocessing.image.ImageDataGenerator(
        rescale=1./255,
        rotation_range=40,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest'
        )
        train_datagen.fit(x)
        self.base_model = keras.applications.MobileNetV3Small(input_shape = (299, 299, 3),include_top = False, weights = 'imagenet')
        inputs = tf.keras.Input(shape=(299, 299, 3))
        pre_in = keras.applications.mobilenet_v3.preprocess_input(inputs)
        x_model = self.base_model(pre_in, training=False)
        global_average_layer = tf.keras.layers.GlobalAveragePooling2D()
        x_model = global_average_layer(x_model)
        x_model = keras.layers.Dropout(0.2)(x_model)
        x_model = keras.layers.Dense(128, activation="relu")(x_model)
        print("PredictionLayer with neurons: {}".format(len(self.img_classes)))
        if len(self.img_classes) > 2:
            self.prediction_layer = tf.keras.layers.Dense(len(self.img_classes),activation="softmax")
        else:
            self.prediction_layer = tf.keras.layers.Dense(1,activation="sigmoid")
        
        outputs = self.prediction_layer(x_model)
        self.model = keras.Model(inputs, outputs)
        self.x = x
        self.y = y

        print("number of imgClasses: {}".format(len(self.img_classes)))
        if len(self.img_classes) > 2:
            print("Compiling with categoricalCrossentropy")
            self.model.compile(optimizer="adam",loss=keras.losses.sparse_categorical_crossentropy,metrics=["accuracy"])
        else:
            print("Compiling with binary crossentropy")
            self.model.compile(optimizer="adam",loss=keras.losses.BinaryCrossentropy(),metrics=["accuracy"])

        self.flow = train_datagen.flow(self.x,self.y, batch_size=2)
        self.model.fit(self.flow, epochs=self.total_epochs,callbacks=[ImageClassifierCallback(self)],validation_split=self.trainingDataRatio,batch_size=2)

    def train_some_more(self,epochs):
        self.model.fit(self.flow, epochs=epochs,callbacks=[ImageClassifierCallback(self)],validation_split=self.trainingDataRatio,batch_size=2)

    def convert_to_mlmodel(self):
        mlmodel = coremltools.convert(self.model,inputs=[coremltools.ImageType(bias=[-1,-1,-1], scale=1/255)],
        input_names=['image'], output_names=['output'], class_labels=self.img_classes, image_input_names='image')
        return mlmodel

    

class ImageClassifierCallback(keras.callbacks.Callback):
            def __init__(self, parent):
                self.parent = parent
                self.total_epochs_trained = 0
            def on_train_begin(self, logs):
                self.parent.parent.update_progress(0.11)
                self.parent.parent.update_status("Training")

            def on_train_end(self, logs):
                keys = list(logs.keys())
                self.model.save("app/tmp/finishedModels/tmpmodel.h5")
                self.parent.parent.finished_and_upload(self.model, self.parent.convert_to_mlmodel)            
            
            def on_epoch_begin(self, epoch, logs):
                self.total_epochs_trained += 1
                self.parent.parent.update_status("Iteration {} out of {}".format(epoch, self.parent.total_epochs))
                if epoch <= self.parent.frozen_epochs:
                    self.parent.base_model.trainable = False
                else:
                    self.parent.base_model.trainable = True

            def on_epoch_end(self, epoch, logs):
                self.parent.parent.update_train_stats(logs.get("accuracy"),logs.get("loss"))
                logs.get("accuracy")
                self.parent.parent.update_progress(epoch / int(self.parent.parent.doc_data.get("epochs") * 85 * 0.01 + 0.11))


import googleapiclient.discovery
from google.cloud import storage as g_storage
def list_sub_directories(path):
    """Returns a list of sub-directories within the given bucket."""
    service = googleapiclient.discovery.build('storage', 'v1')
    req = service.objects().list(bucket="aiologyapp.appspot.com", prefix=path, delimiter='/')
    res = req.execute()
    return res['prefixes']

def list_objects_in_dir(path,bkt):
    storage_client = g_storage.Client()
    bucket = storage_client.get_bucket(bkt)
    blobs_all = list(bucket.list_blobs())
    blobs_specific = list(bucket.list_blobs(prefix=path))
    return blobs_specific
