//
//  ProductStore.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/20/22.
//

import SwiftUI
import Combine

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


class PriceSet: ObservableObject, Identifiable {
    let name: String
    let id = UUID().uuidString
    @Published var prices: [ProductPrice]
    @Published var currency: Currency? = .rub
    
    var cancellable: AnyCancellable?
    var bag = Set<AnyCancellable>()
    internal init(name: String, prices: [ProductPrice] = [], currency: Currency? = .rub) {
        self.name = name
        self.prices = prices
        self.currency = currency
        
        // this is just unacceptable
        $prices.sink { [unowned self] newPrices in
            let objectWillChangeList = newPrices.map(\.objectWillChange)
            Publishers.MergeMany(objectWillChangeList)
                .sink { _ in
                    self.objectWillChange.send()
                }
                .store(in: &bag)
        }
        .store(in: &bag)
    }
}

extension PriceSet: Hashable {
    static func == (lhs: PriceSet, rhs: PriceSet) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

class ProductPrice: ObservableObject, Identifiable {
    internal init(product: Product) {
        self.product = product
    }
    
//    internal init(product: Product) {
//        self.product = product
//        self.price = 0.0
//    }
//
//    internal init(product: Product, price: Double) {
//        self.product = product
//        self.price = price
//    }
    
    var product: Product
    var id: String = UUID().uuidString
    @Published var price: Double = 0.0
    @Published var quantity: Double = 0.0
    @Published var unit: Unit?
    
    var isValid: Bool {
        quantity > 0.0 && unit != nil
    }

}

extension ProductPrice: Hashable{
    static func == (lhs: ProductPrice, rhs: ProductPrice) -> Bool {
        lhs.id == rhs.id 
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(product)
        hasher.combine(price)
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
                ProductPrice(product: productBank.randomElement()!),
                ProductPrice(product: productBank.randomElement()!),
            ]),
            PriceSet(name: "Second", prices: [
                ProductPrice(product: productBank.randomElement()!),
            ]),
            PriceSet(name: "Third", prices: [
                ProductPrice(product: productBank.randomElement()!),
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
