//
//  ContentView.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import SwiftUI
import CoreData
import URLImage
import Firebase
import CoreML
import SwiftUIX

struct ContentView: View{
    let data = (1...1000).map { "Item \($0)" }
    let columns = [
        GridItem(.adaptive(minimum: 170))
    ]
    var body: some View{
        NavigationView{
            VStack{
                Divider().padding()
                LazyVGrid(columns: columns, spacing: 20) {
                    NavigationLink(destination: ImageClassifierPortolioView(), label: {
                        Card(icon:"books.vertical",text:"Machine Learning Portfolio")
                    })
                    
                    NavigationLink(destination: ImageClassifierMMLView(), label: {
                        Card(icon:"photo.on.rectangle.angled",text:"Make Image Classifier")
                    })
                }
                Spacer()
                BottomTrainingActionBar()
            }
            
            .navigationBarTitle("Infinite Img Classifier").padding(.top)
            
            
        }.navigationViewStyle(StackNavigationViewStyle())
        
    }
}

struct ImageClassifierPortolioView:View {
    @FetchRequest(entity: ImageClassifierCD.entity(), sortDescriptors: []) var imageClassifierCDs: FetchedResults<ImageClassifierCD>
    @Environment(\.managedObjectContext) var moc
    var body: some View{
        VStack{
            ForEach(self.imageClassifierCDs,id:\.self){imgClassifier in
                NavigationLink(
                    destination: UseMLView(model: imgClassifier),
                    label: {
                        GrayTextCard(text: imgClassifier.name ?? "no name")
                    })
                
            }
            Spacer()
        }.navigationBarTitle(Text("My ML Portfolio"))
    }
}

struct AiologyMLModel: Hashable, Identifiable {
    var id = UUID()
    var title: String
    var likes: [String]
    var authorID: String
    var modelID: String
    var liked: Bool
    var description: String
    var shareURL: String
    var publicity: String
    var mlmodelDownlaodpath: String
    var docData: [String:AnyHashable]
}

struct UseMLView: View {
    @State var model: ImageClassifierCD
    @State var bgImgURL: URL? = nil
    @FetchRequest(entity: ImageClassifierCD.entity(), sortDescriptors: []) var downloadedMLModels: FetchedResults<ImageClassifierCD>
    
    var body: some View {
        ScrollView{
            VStack{
                Divider()
                    UseImgClassifierView(downloadedMLModel: self.model)
            }
        }.navigationTitle("Use \(self.model.name ?? "")")
        .onAppear{
        }
    }
}

struct GrayImagePickerLibraryOrCameraCard: View {
    @State var text: String
    @State var showImagePickerS = false
    @State var showWhichImagePickerAS = false
    @State var showCameraPicker = false
    @Binding var data: Data?
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        Button(action: {
            self.showWhichImagePickerAS.toggle()
        }, label:{
        Group{
        HStack{
            Spacer()
            Text("\(text): \(self.data == nil ? "Not Picked" : "")")
                .font(.custom("OpenSans-SemiBold", size: 14))
                .foregroundColor(.accentColor)
            if self.data != nil{
                Image(data: self.data!)?
                    .resizable()
                    .frame(width: 20, height: 20)
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
        })
        .actionSheet(isPresented: self.$showWhichImagePickerAS, content: {
                    ActionSheet(title: Text("Choose Your Image Source"), message: Text("Chose the location from which you will pick an image."), buttons: [
                        .default(Text("Photo Album"), action: {
                            self.showImagePickerS.toggle()
                        }),
                        .default(Text("Camera"), action: {
                            self.showCameraPicker.toggle()
                        }),
                        .cancel()
                ])})
        if self.showImagePickerS{
            Text("")
            .sheet(isPresented: self.$showImagePickerS, content: {
                ImagePicker(data: self.$data, encoding: .jpeg(compressionQuality: 0.18))
            })
        }
        if self.showCameraPicker{
            Text("")
                .sheet(isPresented: self.$showCameraPicker,content: {
                    ImagePickerController(sourceType: .camera, inputImage: self.$data)
                })
        }
        
    }
}


struct UseImgClassifierView: View{
    @State var downloadedMLModel: ImageClassifierCD
    @State var imageToPredict: Data? = nil
    @State var output: String = "Output: "
    @State var url: URL? = nil
    @State var mlmodel: MLModel? = nil
    var body: some View{
        VStack{
            //Input
            GrayImagePickerLibraryOrCameraCard(text: "Pick Image To Classify", data: self.$imageToPredict)
            //Use Button
            Button(action: {
                print("ready to classify")
                if let mlmodel = self.mlmodel, let docdj = self.downloadedMLModel.docData, let docData = try? JSONSerialization.jsonObject(with: docdj, options: []) as? [String : Any] {
                    print("none nill")

                    let imageClassifier = try? ImageClassifierModelWrapper(mlmodel: mlmodel)
                    guard let data = self.imageToPredict else { return }
                    guard let uimage = UIImage(data: data) else { return }
                    guard let cgimage = uimage.cgImage else { return }
                    let prediction = try? imageClassifier?.prediction(input: ImageClassifierModelWrapperInput(input_2With: cgimage))
                    print("got prediction: \(prediction), cgimage: \(cgimage)")
                    
                    if let classes = docData["classes"] as? [String], let modelOutput = prediction?.Identity{
                        print("got classes")
                        if classes.count <= 2 {
                            let binarySigmoidPrediction = modelOutput[0].doubleValue
                            let roundedBSPrediction = Int(binarySigmoidPrediction.rounded())
                            print("RoundedBSPrediction: \(roundedBSPrediction), modelOutput: \(modelOutput), classes: \(classes)")
                            self.output = "Output: \(classes[roundedBSPrediction])"
                        } else {
                            let arrayOutput = modelOutput.castToDoubleArray()
                            guard let max = arrayOutput.max() else { return }
                            guard let indx = arrayOutput.firstIndex(of: max) else { return }
                            let finalPrediction = classes[indx]
                            self.output = "Output: \(finalPrediction)"
                        }
                    }
                    
                }
                
            }, label: {
                NavyFilledBigTextButton(text: "Classify", cornerRadius: 4)
            })
            //Output
            GrayBindingTextCard(text: self.$output)
        }
        .onDisappear{
            do {
                guard let url = self.url else { return }
                try FileManager.default.removeItem(at: url)
            } catch let error as NSError {
                print("Error: \(error.domain)")
            }
        }
        .onAppear{
            if let modelData = self.downloadedMLModel.model{
                (self.url, self.mlmodel) = saveToDocDir(file: modelData, name: "imageClassifierTmp")
            }
        }
    }
}

func saveToDocDir(file: Data,name: String)->(URL?,MLModel?){
    let classifierName = name
    var url: URL? = nil
    var mlmodel: MLModel? = nil
    let fileName = NSString(format:"%@.mlmodel",classifierName)
    if let documentsUrl:URL =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
        let destinationFileUrl = documentsUrl.appendingPathComponent(fileName as String)
        try? file.write(to: destinationFileUrl)
        if let compiledModelUrl = try? MLModel.compileModel(at: destinationFileUrl){
            let model = try? MLModel(contentsOf: compiledModelUrl)
            url = compiledModelUrl
            mlmodel = model
        }
    }
    return (url, mlmodel)
}

extension MLMultiArray{
    func castToDoubleArray() -> [Double] {
        let o = self
        var result: [Double] = Array(repeating: 0.0, count: o.count)
        for i in 0 ..< o.count {
            result[i] = o[i].doubleValue
        }
        return result
    }
}



struct NumericalInputItem: Identifiable{
    var name: String
    var value: Double
    var valueStringForm: String
    var id = UUID()
}



struct Card: View{
    var icon: String
    var text: String
    var body: some View{
        VStack{
            Image(systemName: icon)
                .resizable()
                .frame(width: 82, height: 68, alignment: .center)
                .foregroundColor(.accentColor)
                .padding()
                .padding()
                .background(RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color(hex:"F0F5F5"))).shadow(color: Color(hex: "F2F2F2"), radius: 2, x: 1, y: 1).padding(.horizontal)
            
            Text(text)
                .foregroundColor(.accentColor).frame(maxWidth: 170).multilineTextAlignment(.center).font(.custom("Montserrat-Bold", size: 20))
        }
    }
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TrainingModelDoc: Hashable, Identifiable{
    var id = UUID()
    var docID: String
    var modelName: String
}
struct BottomTrainingActionBar:View{
    @State var showSheet: TrainingModelDoc? = nil
    @State var docsInTraining:[TrainingModelDoc] = []
    @Environment(\.managedObjectContext) var moc
    var body: some View{
            VStack{
            if self.docsInTraining.count > 0{
                VStack{
                    Divider()
                    Menu(content: {
                        ForEach(self.docsInTraining, id:\.self){doc in
                            Button(doc.modelName,action:{ self.showSheet = doc})
                        }
                    }, label: {
                        Text("View Current ML Model In Training")
                            .font(.custom("OpenSans-SemiBold", size: 14))
                            .foregroundColor(.accentColor).padding()
                    })
                    
                }
            }
        }
        .onAppear{
            Firestore.firestore().collection("TrainingModels").whereField("user", isEqualTo: "infiniteImageClassifierWildCard").getDocuments(completion: {docs, error in
                if let docs = docs{
                    self.docsInTraining.removeAll()
                    for doc in docs.documents{
                        self.docsInTraining.append(TrainingModelDoc(docID: doc.documentID, modelName: doc.data()["name"] as? String ?? "untitled"))
                    }
                }
            })
        }
        .sheet(item: self.$showSheet, content: {doc in
            NavigationView{
                TrainingObserveView(trainingDocID: doc.docID).environment(\.managedObjectContext, self.moc)
            }
        })
        .onReceive(NotificationCenter.default.publisher(for: .dismissTrainObserveSheet)) {_ in
            
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.showSheet = nil
            }
        }
        
    }
}
extension Notification.Name {
    
    static var dismissTrainObserveSheet: Notification.Name {
        return Notification.Name("dismissTrainObserveSheet")
    }
}


struct ImagePickerController: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType

    @Binding var inputImage: Data?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            pickerController.sourceType = sourceType
        }
        return pickerController
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {

    }

    func makeCoordinator() -> ImagePickerCoordinator {
        Coordinator(self)
    }
}

final class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var parent: ImagePickerController

    init(_ control: ImagePickerController) {
        self.parent = control
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let uiImage = info[.originalImage] as? UIImage {
            parent.inputImage = uiImage.jpegData(compressionQuality: 1)
        }
        dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss()
    }

    private func dismiss() {
        parent.presentationMode.wrappedValue.dismiss()
    }
}
