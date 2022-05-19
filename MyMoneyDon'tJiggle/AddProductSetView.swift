//
//  ContentView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 18.05.2022.
//

import SwiftUI

enum Icon: Hashable {
    case system(String)
}

struct Product: Hashable {
    let icon: Icon
    let name: String
}

enum Currency: String, CaseIterable, Identifiable, CustomStringConvertible {
    var description: String {
        return self.symbol
    }
    
    var id: String {
        return self.rawValue
    }
    
    case usd, rub, ils
    
    var symbol: String {
        switch self {
        case .ils: return "₪"
        case .usd: return "$"
        case .rub: return "₽"
        }
    }
    
    var locale: Locale {
        switch self {
        case .usd: return Locale(identifier: "en_US")
        case .rub: return Locale(identifier: "ru_RU")
        case .ils: return Locale(identifier: "he_IL")
        }
    }
}

final class ProductState: Hashable, ObservableObject {
    init(product: Product) {
        self.product = product
    }
    
    let product: Product
    @Published var cost: Double = 0.0
    
    static func == (lhs: ProductState, rhs: ProductState) -> Bool {
        lhs.product == rhs.product
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(product)
    }
}

final class ProductStore: ObservableObject {
    @Published var currentCurrency: Currency?
    @Published var bank: [Product] = []
    @Published var productStates: [ProductState] = []
    
    init() {
        let products = [
            Product(icon: .system("trash"), name: "Milk"),
            Product(icon: .system("powerplug"), name: "Sugar"),
            Product(icon: .system("dice"), name: "Cream cheese"),
            Product(icon: .system("lock"), name: "Flour")
        ]
        self.productStates += products.map { ProductState(product: $0) }
    }
}

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
