//
//  ProductSelector.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/22/22.
//

import SwiftUI

protocol ProductProvider {
    init(product: Product)
    var product: Product { get set }
}

struct ProductSelector<Item>: View where Item: CustomStringConvertible & Hashable, Item: ProductProvider {
    let allItems: [Product]
    @Binding var selectedProducts: Set<Item>
    @Binding var isProductSelectorShowing: Bool
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            List(filteredProducts, id: \.self) { product in
                ProductSelectorRow(item: product, isInitiallySelected: selectedProducts.contains(where: { $0.product == product})) { isSelected in
                    if isSelected {
                        if !selectedProducts.contains(where: { $0.product == product }) {
                            selectedProducts.insert(Item(product: product))
                        }
                    } else {
                        if let index = selectedProducts.firstIndex(where: { $0.product == product }) {
                            selectedProducts.remove(at: index)
                        }
                    }
                    
                }
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
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { $0.description.contains(searchText) }
        }
    }
}

struct ProductSelectorRow<Item>: View where Item: CustomStringConvertible,
                                            Item: Hashable {
    var item: Item
    var isInitiallySelected: Bool
    var onSelectionChange: (Bool) -> Void
    
    init(item: Item, isInitiallySelected: Bool, onSelectionChange: @escaping (Bool) -> Void) {
        self.item = item
        self.onSelectionChange = onSelectionChange
        self.isInitiallySelected = isInitiallySelected
        self._isSelected = State(initialValue: isInitiallySelected)
    }
    
    @State private var isPressed: Bool = false
    @State private var isSelected: Bool
    
    var body: some View {
        HStack {
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary)
            }
            Text(item.description)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .modifier(
            PressActions(onPress: {
                isPressed = true
            }, onRelease: {
                isPressed = false
                isSelected.toggle()
                onSelectionChange(isSelected)
            })
        )
        .listRowBackground(isPressed ? Color(UIColor.systemFill) : Color.white)
    }
}

//struct ProductSelector_Previews: PreviewProvider {
//    @StateObject private static var store = ProductStore()
//    static var previews: some View {
//        ProductSelector(allItems: store.productBank, selectedProducts: .constant(Set()), isProductSelectorShowing: .constant(true))
//            .environmentObject(store)
//    }
//}

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}
