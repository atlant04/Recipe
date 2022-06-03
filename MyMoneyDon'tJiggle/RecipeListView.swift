//
//  RecipeListView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/23/22.
//

import SwiftUI


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

struct RecipeProduct: Hashable, Identifiable {
    let product: Product
    var unit: Unit?
    var amount: Double
    
    var id = UUID().uuidString
}

struct Recipe: Hashable, Identifiable {
    var name: String
    var products: [RecipeProduct]
    let id = UUID().uuidString
    var priceSet: PriceSet?
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
            List($store.recipeList) { $recipe in
                NavigationLink {
                    RecipeDetailView(recipe: $recipe)
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
