//
//  ProductStore.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/20/22.
//

import SwiftUI
import Combine

enum Icon: Hashable, Codable {
    case system(String)
    case image(UIImage)
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    init(from decoder: Decoder) throws {
        self = .system("asd")
    }
}

extension Product: CustomStringConvertible {
    var description: String { name }
}
struct Product: Hashable, Identifiable, Codable {
    let icon: Icon
    let name: String
    var id = UUID().uuidString
}

extension Product: Comparable {
    static func < (lhs: Product, rhs: Product) -> Bool {
        lhs.name < rhs.name
    }

}

enum Currency: String, CaseIterable, Identifiable, CustomStringConvertible, Codable {
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


class PriceSet: ObservableObject, Identifiable, Codable {
    let name: String
    let id = UUID().uuidString
    @Published var prices: Set<ProductPrice>
    @Published var currency: Currency? = .rub
    
    var cancellable: AnyCancellable?
    var bag = Set<AnyCancellable>()
    internal init(name: String, prices: [ProductPrice] = [], currency: Currency? = .rub) {
        self.name = name
        self.prices = Set(prices)
        self.currency = currency
        
        // this is just unacceptable, plus its leaking memory
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
    
    func totalPrice(for products: Set<RecipeProduct>) -> Double? {
        var totalPrice = 0.0
        for product in products {
            guard let productPrice = self.prices.first(where: { $0.product == product.product })
            else { return nil }
            
            if product.unit != productPrice.unit { return nil }
            if !productPrice.isValid { return nil }
            
            totalPrice += productPrice.pricePerUnit * product.amount
        }
        
        return totalPrice
    }
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    required init(from decoder: Decoder) throws {
        self.name = ""
        self.prices = Set()
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

class ProductPrice: ObservableObject, Identifiable, ProductProvider {
    required init(product: Product) {
        self.product = product
    }
    
    var product: Product
    var id: String = UUID().uuidString
    @Published var price: Double = 0.0
    @Published var quantity: Double = 0.0
    @Published var unit: Unit?
    
    var isValid: Bool {
        quantity > 0.0 && unit != nil
    }
    
    var pricePerUnit: Double {
        return price / quantity
    }

}

extension ProductPrice: CustomStringConvertible {
    var description: String {
        product.description
    }
    
    
}

extension ProductPrice: Hashable{
    static func == (lhs: ProductPrice, rhs: ProductPrice) -> Bool {
        lhs.product == rhs.product
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
final class ProductStore: ObservableObject, Codable {
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
                ProductPrice(product: productBank.randomElement()!),
            ]),
            PriceSet(name: "Second", prices: [
                ProductPrice(product: productBank.randomElement()!),
                ProductPrice(product: productBank.randomElement()!),
                ProductPrice(product: productBank.randomElement()!),
            ]),
            PriceSet(name: "Third", prices: [
                ProductPrice(product: productBank.randomElement()!),
                ProductPrice(product: productBank.randomElement()!),
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
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    enum CodingKeys: String, CodingKey {
        case currentCurrency, productBank, priceSets, recipeList
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.currentCurrency = try container.decodeIfPresent(Currency.self, forKey: .currentCurrency)
        self.productBank = try container.decode([Product].self, forKey: .productBank)
        self.priceSets = try container.decode([PriceSet].self, forKey: .priceSets)
        self.recipeList = try container.decode([Recipe].self, forKey: .recipeList)
    }
}
