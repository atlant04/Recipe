//
//  ProductBankView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 19.05.2022.
//

import SwiftUI


struct ProductBank: View {
    @EnvironmentObject var store: ProductStore
    @State private var newProductName: String = ""
    @State var x: CGFloat = 0
    
    var body: some View {
        VStack {
            List(store.bank, id: \.self) { product in
                HStack {
                    if case .system(let name) = product.icon {
                        Image(systemName: name)
                    }
                    Text(product.name)
                }
            }
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(style: .init(lineWidth: 4, dash: [10], dashPhase: x))
                        .padding() 
                    Image(systemName: "photo.on.rectangle.angled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
//                        .frame(height: 44, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.blue)
                }
                .frame(width: 50, height: 50, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                TextField("Название:", text: $newProductName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
                
            }
            .padding()
        }
    }
}
