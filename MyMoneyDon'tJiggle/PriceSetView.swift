//
//  PriceSetView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/20/22.
//

import SwiftUI

struct PriceSetView: View {
    @EnvironmentObject var store: ProductStore
    @State private var showAlert = false
    @State private var newSetName: String? = ""
    
    var body: some View {
        NavigationView {
            List($store.priceSets) { $priceSet in
                NavigationLink(destination: PriceSetConfigView(priceSet: $priceSet)) {
                    Text(priceSet.name)
                }
            }
            .toolbar {
                Button("Добавить") {
                    showAlert.toggle()
                }
            }
            .textFieldAlert(isPresented: $showAlert, content: {
                TextFieldAlert(alert: TextAlert(title: "Добавить новый набор цен", message: "", action: addNewPriceSet), text: $newSetName)
            })
            .navigationTitle("Наборы Цен")
        }
    }
    
    func addNewPriceSet(_ name: String?) {
        guard let name = name, !name.isEmpty else {
            return
        }
        
        store.addNewPriceSet(name)
    }
}

struct PriceSet_Previews: PreviewProvider {
    private static let store = ProductStore()
    static var previews: some View {
        PriceSetView()
            .environmentObject(store)
    }
}
