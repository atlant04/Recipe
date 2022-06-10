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
        var container = encoder.singleValueContainer()
        try container.encode(self)
    }
    
    init(from decoder: Decoder) throws {
        self = .system("cart")
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
    var id = UUID().uuidString
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
    
    enum CodingKeys: String, CodingKey {
        case name, id, prices, currency
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.prices = try container.decode(Set<ProductPrice>.self, forKey: .prices)
        self.currency = try container.decodeIfPresent(Currency.self, forKey: .currency)
        self.id = try container.decode(String.self, forKey: .id)
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

class ProductPrice: ObservableObject, Identifiable, ProductProvider, Codable {
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
    
    func encode(to encoder: Encoder) throws {
        
    }
    
    enum CodingKeys: String, CodingKey {
        case product, id, price, quantity, unit
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.product = try container.decode(Product.self, forKey: .product)
        self.id = try container.decode(String.self, forKey: .id)
        self.quantity = try container.decode(Double.self, forKey: .quantity)
        self.unit = try container.decode(Unit.self, forKey: .unit)
        self.price = try container.decode(Double.self, forKey: .price)
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
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currentCurrency, forKey: .currentCurrency)
        try container.encode(productBank, forKey: .productBank)
        try container.encode(priceSets, forKey: .priceSets)
        try container.encode(recipeList, forKey: .recipeList)
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
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
        .appendingPathComponent("product_store.data")
    }
    
    static func load(completion: @escaping (Result<ProductStore, Error>)->Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileURL = try fileURL()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success(ProductStore()))
                    }
                    return
                }
                let dailyScrums = try JSONDecoder().decode(ProductStore.self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(dailyScrums))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func save(store: ProductStore, completion: @escaping (Result<Bool, Error>)->Void) {
            DispatchQueue.global(qos: .background).async {
                do {
                    let data = try JSONEncoder().encode(store)
                    let outfile = try fileURL()
                    try data.write(to: outfile)
                    DispatchQueue.main.async {
                        completion(.success(true))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
}
