//
//  RecipeListView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/23/22.
//

import SwiftUI
import Combine

enum Unit: CaseIterable, CustomStringConvertible {
    case kilo, grams, unit
    
    var description: String {
        switch self {
        case .kilo: return "кг."
        case .grams: return "г."
        case .unit: return "ед."
        }
    }
    
}

class RecipeProduct: ObservableObject, Identifiable {
    let product: Product
    @Published var unit: Unit?
    @Published var amount: Double
    
    let id = UUID().uuidString
    
    
    internal init(product: Product, unit: Unit? = nil, amount: Double = 0.0) {
        self.product = product
        self.unit = unit
        self.amount = amount
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

class Recipe: ObservableObject, Identifiable {
    var name: String
    @Published var products: [RecipeProduct]
    let id = UUID().uuidString
    @Published var priceSet: PriceSet?
    
    
    private var bag = Set<AnyCancellable>()
    private var previousSubscription: AnyCancellable?
    
    internal init(name: String, products: [RecipeProduct] = [], priceSet: PriceSet? = nil) {
        self.name = name
        self.products = products
        self.priceSet = priceSet
        
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
