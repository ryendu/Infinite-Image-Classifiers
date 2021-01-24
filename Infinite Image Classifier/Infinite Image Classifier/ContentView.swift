//
//  ContentView.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import SwiftUI
import CoreData
import Firebase

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
            
            .navigationBarTitle("Image Classifier").padding(.top)
            
            
        }.navigationViewStyle(StackNavigationViewStyle())
        
    }
}

struct ImageClassifierPortolioView:View {
    @FetchRequest(entity: ImageClassifierCD.entity(), sortDescriptors: []) var imageClassifierCDs: FetchedResults<ImageClassifierCD>
    @Environment(\.managedObjectContext) var moc
    var body: some View{
        VStack{
            ForEach(self.imageClassifierCDs,id:\.self){imgClassifier in
                //TODO: LINK TO USE ML AND MAKE PRETTY
                Text(imgClassifier.name ?? "no name")
            }
        }.navigationBarTitle(Text("My ML Portfolio"))
    }
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
                TrainingObserveView(trainingDocID: doc.docID)
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
