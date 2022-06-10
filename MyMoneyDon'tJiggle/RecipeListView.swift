//
//  RecipeListView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/23/22.
//

import SwiftUI
import Combine

enum Unit: CaseIterable, CustomStringConvertible, Codable {
    case kilo, grams, unit
    
    var description: String {
        switch self {
        case .kilo: return "кг."
        case .grams: return "г."
        case .unit: return "ед."
        }
    }
    
}

class RecipeProduct: ObservableObject, Identifiable, ProductProvider, CustomStringConvertible, Codable {
    var description: String {
        return product.description
    }
    
    var product: Product
    @Published var unit: Unit?
    @Published var amount: Double
    
    let id = UUID().uuidString
    
    required init(product: Product) {
        self.product = product
        self.unit = .unit
        self.amount = 0.0
    }
    
    
     init(product: Product, unit: Unit? = nil, amount: Double = 0.0) {
        self.product = product
        self.unit = unit
        self.amount = amount
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(product, forKey: .product)
        try container.encode(amount, forKey: .amount)
        try container.encode(unit, forKey: .unit)
    }
    
    enum CodingKeys: String, CodingKey {
        case product, unit, amount
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.product = try container.decode(Product.self, forKey: .product)
        self.unit = try container.decodeIfPresent(Unit.self, forKey: .unit)
        self.amount = try container.decode(Double.self, forKey: .amount)
    }
}

extension RecipeProduct: Hashable {
    static func == (lhs: RecipeProduct, rhs: RecipeProduct) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
}

class Recipe: ObservableObject, Identifiable, Codable {
    var name: String
    @Published var products: Set<RecipeProduct>
    var id = UUID().uuidString
    @Published var priceSet: PriceSet?
    @Published var recipeDescription: String = ""
    @Published var unitsMade: Int = 1
    
    @EnvironmentObject private var store: ProductStore
    
    
    private var bag = Set<AnyCancellable>()
    private var previousSubscription: AnyCancellable?
    
    internal init(name: String, products: [RecipeProduct] = [], priceSet: PriceSet? = nil) {
        self.name = name
        self.products = Set(products)
        self.priceSet = priceSet
        
        registerObservers()
    }
    
    private func registerObservers() {
        // nasty, nasty workaround
        $priceSet.sink { [unowned self] priceSet in
            if let previousSubscription = previousSubscription {
                bag.remove(previousSubscription)
            }
            previousSubscription = priceSet?.objectWillChange.sink {
                self.objectWillChange.send()
            }
        }
        .store(in: &bag)
    
        
        $products.sink { [unowned self] newProducts in
            let objectWillChangeLists = newProducts.map(\.objectWillChange)
            Publishers.MergeMany(objectWillChangeLists)
                .sink { _ in
                    self.objectWillChange.send()
                }
                .store(in: &bag)
        }.store(in: &bag)
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(products, forKey: .products)
        try container.encode(id, forKey: .id)
        try container.encode(priceSet, forKey: .priceSet)
        try container.encode(recipeDescription, forKey: .recipeDescription)
        try container.encode(unitsMade, forKey: .unitsMade)
    }
    
    enum CodingKeys: String, CodingKey {
        case name, products, id, priceSet, recipeDescription, unitsMade
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.products = try container.decode(Set<RecipeProduct>.self, forKey: .products)
        self.id = try container.decode(String.self, forKey: .id)
        self.priceSet = try container.decodeIfPresent(PriceSet.self, forKey: .priceSet)
        self.recipeDescription = try container.decode(String.self, forKey: .recipeDescription)
        self.unitsMade = try container.decode(Int.self, forKey: .unitsMade)
        
        registerObservers()
    }
}

extension Recipe: Hashable {
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
}

extension RecipeProduct: Comparable {
    static func < (lhs: RecipeProduct, rhs: RecipeProduct) -> Bool {
        lhs.product < rhs.product
    }
    
}

struct RecipeListView: View {
    @EnvironmentObject private var store: ProductStore
    @State private var showAlert = false
    @State private var newRecipeName: String?
    var body: some View {
        NavigationView {
            List(store.recipeList) { recipe in
                NavigationLink {
                    RecipeDetailView(recipe: recipe)
                } label: {
                    Text(recipe.name)
                }
            }
            .toolbar {
                Button {
                    showAlert.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .textFieldAlert(isPresented: $showAlert, content: {
                TextFieldAlert(alert: TextAlert(title: "Добавить новый рецепт", message: "", action: addNewRecipe), text: $newRecipeName)
            })
            .navigationTitle("Рецепты")
        }
    }
    
    private func addNewRecipe(_ name: String?) {
        guard let name = name, !name.isEmpty else {
            return
        }

        store.recipeList.append(Recipe(name: name, products: []))
    }
    
    
}

struct RecipeListView_Previews: PreviewProvider {
    @StateObject private static var store = ProductStore()
    static var previews: some View {
        RecipeListView()
            .environmentObject(store)
    }
}
