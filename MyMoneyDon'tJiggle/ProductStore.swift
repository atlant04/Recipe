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

extension Product: CustomStringConvertible {
    var description: String { name }
}
struct Product: Hashable, Identifiable {
    let icon: Icon
    let name: String
    let id = UUID().uuidString
}

extension Product: Comparable {
    static func < (lhs: Product, rhs: Product) -> Bool {
        lhs.name < rhs.name
    }

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


struct PriceSet: Hashable, Identifiable {
    let name: String
    var prices: [ProductPrice]
    var currency: Currency?
    let id = UUID().uuidString
}

struct ProductPrice: Hashable {
    var product: Product
    var price: Double {
        didSet {print(price)}
    }
}

//extension ProductPrice: Equatable {
//    static func == (lhs: Self, rhs: Self) -> Bool {
//        return lhs.product == rhs.product
//    }
//}

extension PriceSet: Comparable {
    static func < (lhs: PriceSet, rhs: PriceSet) -> Bool {
        lhs.name < rhs.name
    }
    
}
final class ProductStore: ObservableObject {
    @Published var currentCurrency: Currency?
    @Published var productBank: [Product] = []
    @Published var priceSets: [PriceSet] = []
    @Published var recipeList: [Recipe] = []
    
    init() {
        self.productBank = [
            Product(icon: .system("trash"), name: "Milk"),
            Product(icon: .system("powerplug"), name: "Sugar"),
            Product(icon: .system("dice"), name: "Cream cheese"),
            Product(icon: .system("lock"), name: "Flour")
        ]
        
        self.priceSets = [
            PriceSet(name: "First", prices: [
                ProductPrice(product: productBank.randomElement()!, price: Double.random(in: 0.0 ... 1.0)),
            ]),
            PriceSet(name: "Second", prices: [
                ProductPrice(product: productBank.randomElement()!, price: Double.random(in: 0.0 ... 1.0)),
            ]),
            PriceSet(name: "Third", prices: [
                ProductPrice(product: productBank.randomElement()!, price: Double.random(in: 0.0 ... 1.0)),
            ]),
        ]
    }
    
    func addNewProduct(_ name: String, icon: UIImage) {
        let product = Product(icon: .image(icon), name: name)
        self.productBank.append(product)
    }
    
    func addNewPriceSet(_ name: String) {
        priceSets.append(PriceSet(name: name, prices: []))
    }
}
