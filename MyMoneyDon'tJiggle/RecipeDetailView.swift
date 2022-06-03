//
//  RecipeDetailView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/23/22.
//

import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var store: ProductStore
    @Binding var recipe: Recipe
    @State private var isProductSelectorShowing = false
    @State private var showPriceSetSelection = false
    @FocusState var focused: Bool
    
    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = recipe.priceSet?.currency?.locale
        return formatter
    }
    
    private var selectedRecipeProducts: Binding<Set<Product>> {
        Binding {
            Set(recipe.products.map(\.product))
        } set: { newProducts in
            let newRecipeProducts = newProducts.map {
                RecipeProduct(product: $0, unit: .unit, amount: 1.0)
            }
            self.recipe.products = Array(Set(newRecipeProducts))
        }
    }
    
    private var recipeProducts: [RecipeProduct] {
        return self.recipe.products.sorted(by: >)
    }
    
    private var totalPrice: Double {
        guard let currentPriceSet = recipe.priceSet else { return 0.0 }
        return recipe.products.reduce(0) { partialResult, recipeProduct in
            let productPrice = currentPriceSet.prices.first(where: {
                $0.product == recipeProduct.product
            })
            
            guard let productPrice = productPrice else {
                return partialResult
            }
            
            return partialResult + (recipeProduct.amount * productPrice.price)
        }
    }
    var body: some View {
        ZStack(alignment: .bottomTrailing){
            VStack {
                ForEach($recipe.products) { $recipeProduct in
                    RecipeProductRow(recipeProduct: $recipeProduct,
                                     focus: _focused)
                }
                RecipeDetailViewSelectorButtons(
                    isProductSelectorShowing: $isProductSelectorShowing,
                    showPriceSetSelection: $showPriceSetSelection,
                    recipe: $recipe
                )
                Spacer()
            }
            if recipe.priceSet != nil {
                Text("Всего: " + (formatter.string(for: totalPrice) ?? ""))
                    .font(.largeTitle)
                    .padding()
            }
        }
        .sheet(isPresented: $showPriceSetSelection) {
            PriceSetSelectionView(selectedPriceSet: $recipe.priceSet,
                                  showPriceSetSelection: $showPriceSetSelection)
        }
        .sheet(isPresented: $isProductSelectorShowing) {
            ProductSelector(allItems: store.productBank,
                            selectedProducts: selectedRecipeProducts,
                            isProductSelectorShowing: $isProductSelectorShowing)
        }
        .onTapGesture {
            focused = false
        }
        .navigationTitle(recipe.name)
    }
}

struct RecipeProductRow: View {
    @Binding var recipeProduct: RecipeProduct
    @FocusState var focus: Bool
    
    var body: some View {
        HStack {
            Text(recipeProduct.product.name)
            Spacer()
            TextField("Кол.", value: $recipeProduct.amount, formatter: NumberFormatter())
                .focused($focus)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 80)
                .padding(4)
                .background(
                    Color(uiColor: UIColor.systemGray5)
                        .cornerRadius(8)
                )
            MenuPicker(selected: $recipeProduct.unit, array: Unit.allCases)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 30)
        }
        .padding()
    }
}

struct RecipeDetailView_Previews: PreviewProvider {
    
    static var previews: some View {
        RecipeDetailView(recipe: .constant(Recipe(name: "Example", products: [
            RecipeProduct(product: Product(icon: .system("plus"), name: "example"), unit: .grams, amount: 200)])))
    }
}

struct RecipeDetailViewSelectorButtons: View {
    @Binding var isProductSelectorShowing: Bool
    @Binding var showPriceSetSelection: Bool
    @Binding var recipe: Recipe
    
    private var selectPriceSetButtonLabel: String {
        if let priceSet = recipe.priceSet {
            return priceSet.name
        }
        
        return "Выбрать ценневой набор"
    }
    
    var body: some View {
        HStack {
            Group {
                Button {
                    self.isProductSelectorShowing.toggle()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .opacity(0.8)
                            .frame(maxHeight: 44)
                        Text("Добавить продукт")
                            .foregroundColor(.blue)
                    }
                }
                
                Button {
                    self.showPriceSetSelection.toggle()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .opacity(0.8)
                            .frame(maxHeight: 44)
                        Text(selectPriceSetButtonLabel)
                            .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(4)
            .background(
                Color(uiColor: UIColor.systemGray5)
                    .cornerRadius(16)
            )
            .padding(4)
            
        }
        .padding(.horizontal, 4)
        .fixedSize(horizontal: false, vertical: true)
    }
}
