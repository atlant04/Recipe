//
//  ProductSelector.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/22/22.
//

import SwiftUI

struct ProductSelector<Item>: View where Item: CustomStringConvertible,
                                         Item: Hashable {
    let allItems: [Item]
    @Binding var selectedProducts: Set<Item>
    @Binding var isProductSelectorShowing: Bool
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            List(filteredProducts, id: \.self, selection: $selectedProducts) { product in
                Text(product.description)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Найти продукт")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                Button("Добавить") {
                    self.isProductSelectorShowing.toggle()
                }
            }
        }
    }
    
    var filteredProducts: [Item] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { $0.description.contains(searchText) }
        }
    }
}

struct ProductSelector_Previews: PreviewProvider {
    @StateObject private static var store = ProductStore()
    static var previews: some View {
        ProductSelector(allItems: store.productBank, selectedProducts: .constant(Set()), isProductSelectorShowing: .constant(true))
            .environmentObject(store)
    }
}
