//
//  MakeImageClassifierView.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import Foundation
import SwiftUI
import UIKit
import Tatsi
import Photos
import URLImage
import Combine
import SwiftUIX
import Firebase

struct ImageClassifierMMLView: View {
    @State var input: [MLImageClassifierClass] = []
    @State var epochs = 2
    @State var trainingDocID = " "
    @State var showNextViewAndTrain = false
    @State var name = ""
    @State var buttonDisabled = false
    @State var frozenEpochs = 1
    var body: some View {
        ZStack{
            ScrollView{
                VStack{
                    Divider().padding()
                    if self.input.count < 1{
                        Text("An image classifier is a ml model that can classify an image in to categories. Add a category / class to classify images into, select images to add to the class, and train your image classifier!")
                            .font(.custom("OpenSans-SemiBold", size: 14))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                    }else{
                        Text("An image classifier is a ml model that can classify an image in to categories. Select images to add to your classes, and train your image classifier!")
                            .font(.custom("OpenSans-SemiBold", size: 14))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    GrayTextFieldCard(placeholderText: "Name Your Image Classifier", text: self.$name, didUpdateValue: {})
                    
                    HStack{
                        Text("Input Data")
                            .foregroundColor(.accentColor)
                            .font(.custom("Montserrat-SemiBold", size: 22))
                            .padding()
                        Spacer()
                    }
                    
                    if self.input.count > 0 {
                        ForEach(0...(self.input.count - 1),id:\.self){indx in
                            ImageClassifierClassView(input: self.$input, MLICClass: self.$input.element(indx))
                        }
                    }
                    GrayPlusTextCard(text: "Add Class", pressedPlus: {
                        withAnimation(){
                            self.input.append(MLImageClassifierClass(className: "", items: []))
                        }
                    })
                    GrayNumberStepperCard(text: "Total Epochs / Iterations", upperRange: 100, lowerRange: 5, value: self.$epochs, step: 1, didUpdateValue: {
                        if self.frozenEpochs >= self.epochs{
                            self.frozenEpochs = self.epochs - 1
                        }
                    })
                    
                    GrayNumberStepperCardWithInfo(text: "Epochs with base frozen", upperRange: 99, lowerRange: 0, value: self.$frozenEpochs, step: 1, didUpdateValue: {
                        if self.frozenEpochs >= self.epochs{
                            self.epochs = self.frozenEpochs + 1
                        }
                    }, infoToShow: "Aiology's Image classification template uses transfer learning which takes what other more powerful image classifiers have learned and apply that to your image classifier. Epochs with base frozen determines the number of iterations the model learns while not changing what the more powerful image classifier learned. After that, it will train for to finetune the result. It is recommended to keep the Epochs with base frozen to atleast 10 and up to 20 epochs.").padding(.horizontal).padding(.leading)
                    
                    NavigationLink(destination: TrainingObserveView(trainingDocID: self.trainingDocID),isActive: self.$showNextViewAndTrain, label: {
                        Button(action: {
                            self.buttonDisabled = true
                            trainingImageClassifier(name: self.name, input: self.input, epochs: self.epochs, uploadedForTraining: {id in
                                self.trainingDocID = id
                                self.showNextViewAndTrain = true
                                self.buttonDisabled = false
                                
                                var request = URLRequest(url: URL(string: "http://0.0.0.0:5000/trainImageClassifier?id=\(id)")!)
                                request.httpMethod = "GET"

                                let session = URLSession.shared
                                let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                                    print(response!)
                                })
                                task.resume()
                            },frozenEpochs: self.frozenEpochs)
                            
                            
                            
                        }, label: {
                            NavyFilledBigTextButton(text: "Train", cornerRadius: 4)
                        }).disabled(self.buttonDisabled)
                    })
                }
            }.navigationTitle("Image Classifier")
            
            
            ProgressView().progressViewStyle(CircularProgressViewStyle()).padding().background(Rectangle().opacity(0.4)).hidden(!self.buttonDisabled)
            
        }
    }
}

struct IdentifiableInt:Identifiable, Hashable{
    var id = UUID()
    var value: Int
}

struct ImageClassifierClassView:View{
    @State var showImagePicker = false
    @Binding var input: [MLImageClassifierClass]
    let columns = [
        GridItem(.adaptive(minimum: 65))
    ]
    @State var showDeleteAS: IdentifiableInt? = nil
    @Binding var MLICClass: MLImageClassifierClass
    
    @State var showDeleteClassAS = false
    var body: some View{
        VStack{
            Group{
                Group{
                    GrayTextFieldCard(placeholderText: "Image Class Label", text: self.$MLICClass.className, didUpdateValue: {}).padding(.top)
                }
                .onTapGesture {}
                .gesture(LongPressGesture().onEnded{_ in
                    simpleSuccessHapticOnly()
                    self.showDeleteClassAS.toggle()
                })
                .actionSheet(isPresented: self.$showDeleteClassAS,content:{
                    ActionSheet(title: Text("Delete This Class?"),message: Text("Are you sure you want to delete this class?"),buttons: [
                        .destructive(Text("Delete"), action: {
                            if let indx = self.input.firstIndex(of: self.MLICClass){
                                self.input.remove(at: indx)
                            }
                        })
                        ,.cancel()
                    ])
                })
                
                Group{
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(self.MLICClass.items, id: \.self) { item in
                            Group{
                                if item != nil{
                                    Image(uiImage: item!).resizable().frame(width: 65, height: 65).padding()
                                }
                            }
                            .onTapGesture {}
                            .gesture(LongPressGesture().onEnded{_ in
                                simpleSuccessHapticOnly()
                                if let indx = self.MLICClass.items.firstIndex(of: item){
                                    self.showDeleteAS = IdentifiableInt(value:indx)
                                }
                            })
                            .actionSheet(item: self.$showDeleteAS,content:{ a in
                                ActionSheet(title: Text("Remove This Image?"),message: Text("Are you sure you want to Remove this image from your training dataset? It will not be removed on your device and you can add it again."),buttons: [
                                    .destructive(Text("Delete"), action: {
                                        self.MLICClass.items.remove(at: a.value)
                                    })
                                    ,.cancel()
                                ])
                            })
                        }
                    }.padding(.horizontal)
                    
                    Button(action: {
                        self.showImagePicker.toggle()
                    }, label: {
                        GrayTextCard(text: "Pick Images")
                    }).sheet(isPresented: self.$showImagePicker, content: {
                        MultiImagePicker(images: self.$MLICClass.items)
                    })
                }.padding(.leading)
            }.padding(.leading)
        }
    }
}

struct MLImageClassifierClass: Hashable{
    var className: String
    var items: [UIImage?]
}
extension Binding where Value: MutableCollection, Value.Index == Int {
    func element(_ idx: Int) -> Binding<Value.Element> {
        return Binding<Value.Element>(
            get: {
                return self.wrappedValue[idx]
            }, set: { (value: Value.Element) -> () in
                self.wrappedValue[idx] = value
            })
    }
}
struct GrayTextFieldCard: View {
    @State var placeholderText: String
    @Binding var text: String
    @State var didUpdateValue: ()->Void
    var body: some View {
        HStack{
            TextField(self.placeholderText, text: self.$text)
                .font(.custom("OpenSans-SemiBold", size: 14))
                .foregroundColor(.accentColor)
                .onChange(of: self.text, perform:{ value in
                    didUpdateValue()
                })
            
        }
        .frame(minHeight: 16, idealHeight: 16)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color("secondaryBackground"))
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct GrayTextCard: View {
    @State var text: String
    @State var color: Color?
    var body: some View {
        Group{
            HStack{
                Spacer()
                Text(text)
                    .font(.custom("OpenSans-SemiBold", size: 14))
                    .foregroundColor(self.color == nil ? .accentColor : self.color!)
                
                Spacer()
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 16)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(Color("secondaryBackground"))
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct MultiImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var images: [UIImage?]
    var picker: TatsiPickerViewController
    init(images: Binding<[UIImage?]>){
        self._images = images
        var config = TatsiConfig.default
        config.showCameraOption = true
        config.supportedMediaTypes = [.image]
        config.firstView = .userLibrary
        self.picker = TatsiPickerViewController(config: config)
    }
    func makeUIViewController(context: UIViewControllerRepresentableContext<MultiImagePicker>) -> TatsiPickerViewController {
        return picker
    }
    
    func updateUIViewController(_ uiViewController: TatsiPickerViewController, context: UIViewControllerRepresentableContext<MultiImagePicker>) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate,TatsiPickerViewControllerDelegate {
        
        func pickerViewController(_ pickerViewController: TatsiPickerViewController, didPickAssets assets: [PHAsset]) {
            print("Picked assets: \(assets)")
            //TODO: get UIImage out of PHAsset swift'
            let manager = PHImageManager.default()
            let option = PHImageRequestOptions()
            option.isSynchronous = true
            for i in assets{
                manager.requestImage(for: i, targetSize: CGSize(width: 299, height: 299), contentMode: .aspectFill, options: option, resultHandler: {uimage, _ in
                    self.parent.images.append(uimage)
                })
            }
            self.parent.presentationMode.wrappedValue.dismiss()
        }
        
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
            super.init()
            self.parent.picker.pickerDelegate = self
            self.parent.picker.delegate = self
        }
        
        
    }
}


extension PHAsset{
    public func uiimage()->UIImage?{
        var img: UIImage?
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .original
        options.isSynchronous = true
        manager.requestImageData(for: self, options: options) { data, _, _, _ in
            
            if let data = data {
                img = UIImage(data: data)
            }
        }
        return img
    }
}

struct GrayNumberStepperCard: View {
    @State var text: String
    @State var upperRange: Int
    @State var lowerRange: Int
    @Binding var value: Int
    @State var step: Int
    @State var didUpdateValue: ()->Void
    
    var body: some View {
        HStack{
            Text("\(text): \(self.value)")
                .font(.custom("OpenSans-SemiBold", size: 14))
                .foregroundColor(.accentColor)
                .minimumScaleFactor(0.8)
            Spacer()
            
            Stepper(value: $value, in: lowerRange...upperRange, step: step) {
                
            }.labelsHidden()
            .onChange(of: self.value, perform:{ value in
                didUpdateValue()
            })
            .minimumScaleFactor(0.6)
        }.frame(minHeight: 16, idealHeight: 16)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color("secondaryBackground"))
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct GrayNumberStepperCardWithInfo: View {
    @State var text: String
    @State var upperRange: Int
    @State var lowerRange: Int
    @Binding var value: Int
    @State var step: Int
    @State var didUpdateValue: ()->Void
    @State var showInfo = false
    @State var infoToShow: String
    var body: some View {
        HStack{
            Text("\(text): \(self.value)")
                .font(.custom("OpenSans-SemiBold", size: 14))
                .foregroundColor(.accentColor)
                .minimumScaleFactor(0.8)
            Spacer()
            
            Stepper(value: $value, in: lowerRange...upperRange, step: step) {
                
            }.labelsHidden()
            .onChange(of: self.value, perform:{ value in
                didUpdateValue()
            })
            .minimumScaleFactor(0.6)
            Button(action: {
                self.showInfo.toggle()
            }, label: {
                Image(systemName: "info.circle")
            })
            .popover(isPresented: self.$showInfo) {
                Text(self.infoToShow)
                    .font(.custom("OpenSans-SemiBold", size: 14))
                    .foregroundColor(.accentColor)
                    .minimumScaleFactor(0.8)
            }
        }.frame(minHeight: 16, idealHeight: 16)
        .fixedSize(horizontal: false, vertical: true)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color("secondaryBackground"))
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct GrayPlusTextCard: View {
    @State var text: String
    @State var pressedPlus: () -> Void
    var body: some View {
        HStack{
            Button(action: {
                self.pressedPlus()
            }){
                Spacer()
                Text(self.text)
                    .font(.custom("OpenSans-SemiBold", size: 14))
                    .foregroundColor(.accentColor)
                    .minimumScaleFactor(0.85)
                Image(systemName: "plus")
                Spacer()
            }
        }.frame(minHeight: 16, idealHeight: 16)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color("secondaryBackground"))
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct NavyFilledBigTextButton: View {
    @State var text: String
    @State var cornerRadius: CGFloat
    var body: some View {
        VStack{
            HStack{
                Spacer()
                Text(text)
                    .foregroundColor(.white)
                    .font(.custom("Montserrat-SemiBold", size: 18))
                    .padding()
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundColor(.accentColor)
                    .frame(minHeight: 45, maxHeight: 55)
                    .padding()
            )
        }
        //        .padding(.horizontal)
    }
}

struct TrainingObserveView: View {
    @State var currentTokens = 0
    @State var possibleHardware = ["cpu", "gpu"]
    @State var detailStatus = "sending dataset and training information and looking for virtual machine."
    @State var progress = 0.0
    @State var tokensUsed = 0
    @State var status = "Waiting for training to start"
    @State var trainingDocID: String
    @State var trainingDocData: [String:Any]? = nil
    @State var activityItem: Any? = nil
    @State var showActivityIndicator = false
    @State var showDetailedStatus = false
    @State var isDone = false
    @State var error = ""
    @State var acc: Double? = nil
    @State var loss: Double? = nil
    @State var sampleGANImages: [IdentifiableGANImageURL] = []
    var body: some View {
        ScrollView{
            VStack{
                Divider().padding()
                ProgressView(value: progress).padding(.horizontal)
                GrayBindingTextCard(text: $status)
                if self.isDone{
                    NavigationLink(destination: AfterTrainingView(trainingDocID: self.trainingDocID), label: {
                        NavyFilledBigTextButton(text: "Continue", cornerRadius: 4)
                    })
                }
                
                if self.trainingDocData?["type"] as? String != nil{
                    if self.trainingDocData?["type"] as! String == "imageClassifier" || self.trainingDocData?["type"] as! String == "imageRegressor"{
                        
                        GrayBindingAccAndLossCard(acc: self.$acc, loss: self.$loss)
                        
                        
                    } else if self.trainingDocData?["type"] as! String == "GANImageGenerator"{
                        GANImageGeneraterTrainingObserveView(trainingDocData: self.$trainingDocData, sampleImageURLs: self.$sampleGANImages)
                    }
                }
                
                
                
                
                
            }
            .navigationTitle("Training")
            .onAppear{
                print("Observing training with docID: \(self.trainingDocID)")
                // send for training
                observeTraining(docId: self.trainingDocID, progressUpdate: {observedInfo in
                    
                    self.detailStatus = observedInfo.detailStatus
                    withAnimation(){
                        self.progress = observedInfo.progress
                    }
                    self.tokensUsed = observedInfo.tokensUsed
                    self.status = observedInfo.status
                    if self.status == "Finished!"{
                        self.isDone = true
                    } else{
                        self.isDone = false
                    }
                    self.error = observedInfo.trainingError
                    print("got observed Info and training is: \(self.isDone)")
                    
                }, gotData: {data in
                    if data["type"] as? String? == "GANImageGenerator", let sampleImages = data["sampleImagePaths"] as? [String]{
                        
                        for i in sampleImages{
                            if !self.sampleGANImages.contains(where: {$0.ganID == i}){
                                Storage.storage().reference(withPath: "GANSampleImages/\(i).jpg").downloadURL(completion: {url,_ in
                                    guard let url = url else {return}
                                    self.sampleGANImages.insert(IdentifiableGANImageURL(value: url, ganID: i), at: 0)
                                })
                            }
                        }
                    }
                    
                    self.trainingDocData = data
                    if let acc = data["accuracy"] as? Double{
                        self.acc = acc
                    }
                    if let loss = data["loss"] as? Double{
                        self.loss = loss
                    }
                })
                
            }
        }
    }
}

struct IdentifiableGANImageURL: Hashable, Identifiable{
    var value: URL
    var id = UUID()
    var ganID: String
}

//MARK: Custom Observe Views
struct GANImageGeneraterTrainingObserveView: View{
    @Binding var trainingDocData: [String:Any]?
    @Binding var sampleImageURLs: [IdentifiableGANImageURL]
    let columns = [
        GridItem(.adaptive(minimum: 160))
    ]
    var body: some View{
        VStack{
            if self.sampleImageURLs.count > 0{
                GrayTextCard(text: "Generated Images")
                GraySmallTextCard(text: "The Images generated below might be complete random noise at first but will eventually come out looking similar to the images you gave it to train.").padding(.leading)
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(self.sampleImageURLs, id: \.self) { img in
                        VStack{
                            SampleImageDisplay(sampleImageURLs: self.$sampleImageURLs, url: img)
                        }.padding(.bottom).padding()
                    }
                }.padding().padding(.leading)
            }
        }
    }
}
struct SampleImageDisplay:View{
    @Binding var sampleImageURLs: [IdentifiableGANImageURL]
    @State var url: IdentifiableGANImageURL
    var body: some View{
        VStack{
            URLImage(url: url.value,
                     content: { image in
                        return VStack{
                            image
                                .resizable().frame(width: 120, height: 120).padding(.horizontal).padding(.top).padding(.bottom,2)
                            Text("Epoch \(self.sampleImageURLs.count - ((self.sampleImageURLs.firstIndex(of: url) ?? 0)))")
                                .font(.custom("OpenSans-SemiBold", size: 14))
                                .foregroundColor(.accentColor)
                        }
                     })
        }
    }
}

struct GrayChevronToggleCard: View {
    @Binding var toggle: Bool
    @State var text: String
    var body: some View {
        HStack{
            Text(self.text)
                .font(.custom("OpenSans-SemiBold", size: 14))
                .foregroundColor(.accentColor)
                .minimumScaleFactor(0.85)
            Spacer()
            Button(action: {
                withAnimation{
                    self.toggle.toggle()
                }
            }, label: {
                Image(systemName: "chevron.up").rotationEffect(Angle(degrees: self.toggle ? 180 : 0))
            })
            
        }.frame(minHeight: 16, idealHeight: 16)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 4)
                .foregroundColor(Color("secondaryBackground"))
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct GrayBindingTextCard: View {
    @Binding var text: String
    
    var body: some View {
        Group{
            HStack{
                Spacer()
                Text(text)
                    .font(.custom("OpenSans-SemiBold", size: 14))
                    .foregroundColor(.accentColor)
                
                Spacer()
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 16)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(Color("secondaryBackground"))
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct GrayBindingAccAndLossCard: View {
    @Binding var acc: Double?
    @Binding var loss: Double?
    var body: some View {
        if self.acc != nil || self.loss != nil{
            Group{
                HStack{
                    Spacer()
                    if self.acc != nil{
                        Text("Accuracy: \((self.acc! * 100).rounded())%")
                            .font(.custom("OpenSans-SemiBold", size: 14))
                            .foregroundColor(.accentColor)
                    }
                    if self.loss != nil{
                        Text("Loss: \(self.loss!)")
                            .font(.custom("OpenSans-SemiBold", size: 14))
                            .foregroundColor(.accentColor)
                    }
                    
                    
                    Spacer()
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 16)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(Color("secondaryBackground"))
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct GraySmallTextCard: View {
    @State var text: String
    
    var body: some View {
        Group{
            HStack{
                Spacer()
                Text(text)
                    .font(.custom("OpenSans-SemiBold", size: 11))
                    .foregroundColor(.accentColor)
                
                Spacer()
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 16)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(Color("secondaryBackground"))
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct AfterTrainingView: View {
    @State var trainingDocID: String
    @State var docData: [String:Any] = [:]
    @FetchRequest(entity: ImageClassifierCD.entity(), sortDescriptors: []) var imageClassifierCDs: FetchedResults<ImageClassifierCD>
    @Environment(\.managedObjectContext) var moc
    
    
    var body: some View {
        ScrollView{
            VStack{
                Divider().padding()
                Text("Congrats 🎉! You just finished training your ML Model! Once you click Save and Finish, your Image Classifier will be saved on your device and you can find it in your ML Portfolio.")
                    .font(.custom("OpenSans-Regular", size: 15)).padding().padding(.horizontal)
                
                
                GrayExportModelCard(docData: self.$docData, type: DownloadModelType.mlmodel).padding(.horizontal)
                
                NavigationLink(destination: ContentView(), label: {
                    NavyFilledBigTextButton(text: "Save and Finish", cornerRadius: 4)
                }).simultaneousGesture(TapGesture().onEnded({
                    //TODO: SAVE IN COREDADA
                    
                    do {
                        print(1)
                        let jsonData = try JSONSerialization.data(withJSONObject: self.docData, options: .prettyPrinted)
                        print(2)
                        let newICCD = ImageClassifierCD(context: self.moc)
                        print(3)
                        newICCD.docData = jsonData
                        print(4)
                        newICCD.id = UUID()
                        guard let nm = self.docData["name"] as? String else {return}
                        print(5)
                        newICCD.name = nm
                        print(6)
                        downloadMLModel_(type: .mlmodel, docData: self.docData, gotData: {data in
                            print(7)
                            newICCD.model = data
                            print(8)
                            try? self.moc.save()

                            if let type = self.docData["type"] as? String{
                                let trainingDatasetUUID = self.docData["trainingDatasetUUID"] as? String ?? "nonexistent"
                                let modelStorageUUID = self.docData["modelStorageUUID"] as? String ?? "None"
                                Functions.functions().httpsCallable("deleteTrainModelDontSaveOnAiology").call([
                                    "trainingDatasetUUID": trainingDatasetUUID,"modelStorageUUID": modelStorageUUID,"type": type,"docID": self.trainingDocID
                                ]) { _,_ in }
                                Firestore.firestore().collection("TrainingModels").document(self.trainingDocID).delete()

                            }
                            NotificationCenter.default.post(name: .dismissTrainObserveSheet, object: nil)
                        })

                    } catch {
                        print(error.localizedDescription)
                    }
                    
                    
                    
                }))
            }
        }
        .navigationTitle(Text("Saving"))
        .onAppear{
            print("APPEARED AFTER")
            let trainDocRef = Firestore.firestore().collection("TrainingModels").document(self.trainingDocID)
            trainDocRef.getDocument(completion: {document, error in
                if let error = error{
                    print(error.localizedDescription)
                }
                if let doc = document, let data = doc.data(){
                    self.docData = data
                }
            })
        }
        
    }
}

func downloadMLModel_(type:DownloadModelType,docData:[String:Any],gotData:@escaping (Data)->Void){
    if let modelPath = docData["mlmodelPath"] as? String{
        print("got model path")
        DispatchQueue.main.async {
            let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let file2ShareURL = documentsDirectoryURL.appendingPathComponent("model.mlmodel")
            let pathReference = Storage.storage().reference(withPath: "CompletedModels/\(modelPath)")
            pathReference.downloadURL(completion: {url, error in
                if let url = url{
                    guard let data = try? Data(contentsOf: url) else {return}
                    gotData(data)
                }
            })
        }
    }else{
    }
}

struct GrayExportModelCard: View {
    @State var progress = 0.0
    @Binding var docData: [String:Any]
    @State var type: DownloadModelType
    @State var activityItem: Any? = nil
    @State var showActivityIndicator = false
    func downloadMLModel(type:DownloadModelType,gotProgress:@escaping (Double)->Void){
        if let modelPath = docData[type == DownloadModelType.h5 ? "h5modelPath" : "mlmodelPath"] as? String{
            print("got model path")
            DispatchQueue.main.async {
                let documentsDirectoryURL = try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let file2ShareURL = documentsDirectoryURL.appendingPathComponent("model.mlmodel")
                let pathReference = Storage.storage().reference(withPath: "CompletedModels/\(modelPath)")
                let downloadTask = pathReference.write(toFile: file2ShareURL) {_,_ in }
                downloadTask.observe(.progress, handler: { snapshot in
                    guard let progress = snapshot.progress?.fractionCompleted else { return }
                    gotProgress(progress)
                })
                self.activityItem = file2ShareURL
                self.showActivityIndicator.toggle()
            }
        }else{
            print("Model path didnt get from \(self.type == DownloadModelType.h5 ? "h5modelPath" : "mlmodelPath"), our attempt to get here: \(docData[type == DownloadModelType.h5 ? "h5modelPath" : "mlmodelPath"] as? String), with doc data \(self.docData)")
        }
    }
    var body: some View {
        Button(action: {
            downloadMLModel(type: self.type, gotProgress: {p in
                self.progress = p
            })
        },label:{
            Group{
                VStack{
                    HStack{
                        Spacer()
                        Text(self.type == DownloadModelType.h5 ? "Export .h5 File" : "Export .mlmodel File")
                            .font(.custom("OpenSans-SemiBold", size: 14))
                            .foregroundColor(.accentColor)
                        
                        Spacer()
                    }
                    if self.progress > 0{
                        ProgressView(value: self.progress,total:1).progressViewStyle(LinearProgressViewStyle())
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 16)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(Color("secondaryBackground"))
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .fixedSize(horizontal: false, vertical: true)
        }).sheet(isPresented: self.$showActivityIndicator, onDismiss: {
            print("Dismiss")
        }, content: {
            ActivityViewController(activityItems: [self.activityItem as Any])
        })
    }
}

enum DownloadModelType{
    case h5
    case mlmodel
}

struct ActivityViewController: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
    
}

