//
//  supportingFunctions.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import Foundation
import UIKit
import SwiftUI
import Firebase
func simpleSuccessHapticOnly() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
}

func trainingImageClassifier(name: String,input: [MLImageClassifierClass],epochs: Int,uploadedForTraining:(String)->Void,frozenEpochs:Int){
    let trainingDatasetUUID = UUID().uuidString
    //Upload training images
    for imgClass in input{
        for img in imgClass.items{
            if let img = img, let data = img.jpegData(compressionQuality: 1){
                let uuid = UUID().uuidString
                let meta = StorageMetadata.init()
                meta.contentType = "image/jpeg"
                let storagePath = Storage.storage().reference(withPath: "Datasets/ImageClassifierDatasets/\(trainingDatasetUUID)/\(imgClass.className)/\(uuid).jpg")
                storagePath.putData(data, metadata: meta, completion: {_,_ in })
            }
        }
    }
    //upload training doc
    let newData: [String:Any] = [
        "type": "imageClassifier",
        "name":name,
        "trainDataRatio":0.8,
        "epochs":epochs,
        "status":"pending",
        "userRequestedTask":"BeginTraining",
        "progress":0.0,
        "user": "infiniteImageClassifierWildCard",
        "trainingDatasetUUID": trainingDatasetUUID,
        "classes": input.map{$0.className},
        "frozenEpochs": frozenEpochs,
        "total_epochs_trained":0,
    ]
    let newDoc = Firestore.firestore().collection("TrainingModels").addDocument(data: newData, completion: {err in
        if let err = err{
            print(err.localizedDescription)
        }else{
            
        }
    })
    
    uploadedForTraining(newDoc.documentID)
}

func observeTraining(docId: String, progressUpdate: @escaping (ObservedTrainingInfo)->Void, gotData:@escaping ([String:Any])->Void){
    
    Firestore.firestore().collection("TrainingModels").document(docId).addSnapshotListener({snapshot, error in
        if let error = error{
            print(error.localizedDescription)
        }
        if let data = snapshot?.data(){
            gotData(data)
            let detailStatus = data["detailStatus"] as? String ?? ""
            let progress = data["progress"] as? Double ?? 0.0
            let tokensUsed = data["tokensUsed"] as? Int ?? 0
            let status = data["status"] as? String ?? ""
            let trainingError = data["error"] as? String ?? ""
            let observedTInfo = ObservedTrainingInfo(detailStatus: detailStatus, progress: progress, tokensUsed: tokensUsed, status: status, trainingError: trainingError)
            progressUpdate(observedTInfo)
        }
    })
    
}

struct ObservedTrainingInfo {
    var detailStatus: String
    var progress: Double
    var tokensUsed: Int
    var status: String
    var trainingError: String
}
