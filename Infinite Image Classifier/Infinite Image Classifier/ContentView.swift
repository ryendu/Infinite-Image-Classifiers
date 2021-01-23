//
//  ContentView.swift
//  Infinite Image Classifier
//
//  Created by Ryan Du on 1/22/21.
//

import SwiftUI
import CoreData

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
                        Card(icon:"books.vertical",text:"Image Classifier Portfolio")
                    })
                    
                    NavigationLink(destination: ImageClassifierMMLView(), label: {
                        Card(icon:"photo.on.rectangle.angled",text:"Make Image Classifier")
                    })
                }
                Spacer()
            }
            
            .navigationBarTitle("Image Classifier").padding(.top)
            
            
        }.navigationViewStyle(StackNavigationViewStyle())
        
    }
}

struct ImageClassifierPortolioView:View {
    var body: some View{
        VStack{
            
        }.navigationBarTitle(Text("My IC Portfolio"))
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
                .foregroundColor(Color(hex: "3A506B"))
                .padding()
                .padding()
                .background(RoundedRectangle(cornerRadius: 20)
                                .foregroundColor(Color(hex:"F0F5F5"))).shadow(color: Color(hex: "F2F2F2"), radius: 2, x: 1, y: 1).padding(.horizontal)
            
            Text(text)
                .foregroundColor(Color(hex:"3A506B")).frame(maxWidth: 170).multilineTextAlignment(.center).font(.custom("Montserrat-Bold", size: 20))
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

