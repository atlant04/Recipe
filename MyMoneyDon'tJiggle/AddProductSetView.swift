//
//  ContentView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 18.05.2022.
//

import SwiftUI

struct AddProductSetView: View {
    @EnvironmentObject var store: ProductStore
    var body: some View {
        NavigationView {
            List(store.productStates, id: \.self) { state in
                ProductRow(productState: state)
            }
            .navigationBarTitle("Продукты")
            .toolbar(content: {
                MenuPicker(selected: $store.currentCurrency, array: Currency.allCases, defaultTitle: "Валюта")
            })
        }
        .environmentObject(store)
    }
}

struct ProductRow: View {
    let productState: ProductState
    var product: Product { productState.product }
    
    @State private var cost: Double = 0.0
    @EnvironmentObject var store: ProductStore
    
    init(productState: ProductState) {
        self.productState = productState
    }
    
    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = store.currentCurrency?.locale ?? Currency.rub.locale
        return formatter
    }
    
    var body: some View {
        HStack {
            if case .system(let name) = product.icon {
                Image(systemName: name)
            }
            Text(product.name)
            Spacer()
            CurrencyTextField(numberFormatter: formatter, value: $cost)
                .font(.caption)
                .frame(minWidth: 92, alignment: .trailing)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject private static var store = ProductStore()
    static var previews: some View {
        AddProductSetView()
            .environmentObject(store)
    }
}

@available (iOS 14.0, *)
public struct MenuPicker<T>: View where T: Hashable & CustomStringConvertible {
    
    @Binding var selected: T?
    var array: [T]
    var defaultTitle: String
    
    var title: String {
        selected?.description ?? defaultTitle
    }
    
    public init(selected: Binding<T?>, array: [T], defaultTitle: String = "") {
        self._selected = selected
        self.array = array
        self.defaultTitle = defaultTitle
    }
    
    public var body: some View {
        Menu(self.title, content: {
            ForEach(array, id: \.self) { item in
                Button(action: {
                    selected = item
                }, label: {
                    view(for: item)
                })
            }
        })
    }

    
    @ViewBuilder func view(for item: T) -> some View {
        if let selected = self.selected,
           selected == item {
            HStack {
                Image(systemName: "checkmark")
                Text(selected.description)
            }
        } else {
            Text(item.description)
        }
    }
}
