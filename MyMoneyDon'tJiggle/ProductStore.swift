//
//  ProductStore.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/20/22.
//

import SwiftUI


enum Icon: Hashable {
    case system(String)
    case image(UIImage)
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

struct PriceSet: Hashable {
    let name: String
    var set: [Product: Double]
}
final class ProductStore: ObservableObject {
    @Published var currentCurrency: Currency?
    @Published var bank: [Product] = []
    @Published var productStates: [ProductState] = []
    @Published var priceSets: [PriceSet] = []
    
    init() {
        let products = [
            Product(icon: .system("trash"), name: "Milk"),
            Product(icon: .system("powerplug"), name: "Sugar"),
            Product(icon: .system("dice"), name: "Cream cheese"),
            Product(icon: .system("lock"), name: "Flour")
        ]
        self.productStates += products.map { ProductState(product: $0) }
    }
    
    func addNewProduct(_ name: String, icon: UIImage) {
        let product = Product(icon: .image(icon), name: name)
        self.bank.append(product)
    }
    
    func addNewPriceSet(_ name: String) {
        priceSets.append(PriceSet(name: name, set: [:]))
    }
}
