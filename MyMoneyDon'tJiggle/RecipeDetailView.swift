//
//  RecipeDetailView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/23/22.
//

import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject var store: ProductStore
    @ObservedObject var recipe: Recipe
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
    
    enum RecipeProductValidity {
        case noPriceSetIsSelected
        case productIsMissingInPriceSet
        case productPriceIsInvalid
        case mismatchedUnits
        case valid
        
        var validityDescription: String {
            switch self {
            case .noPriceSetIsSelected:
                return "Не выбран набор цен"
            case .productIsMissingInPriceSet:
                return "Этот продукт не входит в выбранный набор цен"
            case .productPriceIsInvalid:
                return "Не действительная цена продукта в выбранном наборе цен"
            case .mismatchedUnits:
                return "Единицы измерения в ценновом наборе и в этом продукте отличаются"
            case .valid:
                return "Все ОК"
            }
        }
    }
    
    private func checkValidity(for recipeProduct: RecipeProduct) -> RecipeProductValidity {
        //check priseSet is selected for current recipe
        guard let priceSet = recipe.priceSet else { return .noPriceSetIsSelected }
        
        // find price for the given product from the priceSet, return red if not found
        guard let productPrice = priceSet.prices.first(where: {
            $0.product == recipeProduct.product
        }) else { return .productIsMissingInPriceSet }
        
        // if price for a product is not valid, return red
        if !productPrice.isValid {
            return .productPriceIsInvalid
        }
        
        if recipeProduct.unit != productPrice.unit {
            return .mismatchedUnits
        }
    
        return .valid
        
    }
    var body: some View {
        ZStack(alignment: .bottomTrailing){
            ScrollView {
                VStack {
                    ForEach(recipe.products) { recipeProduct in
                        let validity = checkValidity(for: recipeProduct)
                        VStack {
                            RecipeProductRow(recipeProduct: recipeProduct,
                                             focus: _focused)
                            
                            if validity != .valid {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .resizable()
                                    .frame(width: 16, height: 16)
                                    Text(validity.validityDescription)
                                    Spacer()
                                }
                                .padding(4)
                            }
                        }
                        .background(validity == .valid ? .green : .red)
                    }
                    VStack(alignment: .leading, spacing: 0){
                        Text("Описание")
                            .font(.title)
                            .fontWeight(.medium)
                        TextEditor(text: $recipe.recipeDescription)
                            .foregroundColor(.secondary)
                        .frame(minHeight: 200)
                    }
                    .padding(.horizontal)
                    RecipeDetailViewSelectorButtons(
                        isProductSelectorShowing: $isProductSelectorShowing,
                        showPriceSetSelection: $showPriceSetSelection,
                        recipe: recipe
                    )
                    Spacer()
                }
            }
            .padding(.bottom, 64)
            if let totalPrice = recipe.priceSet?.totalPrice(for: recipe.products) {
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
    @ObservedObject var recipeProduct: RecipeProduct
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
        RecipeDetailView(recipe: Recipe(name: "Example", products: [
            RecipeProduct(product: Product(icon: .system("plus"), name: "example"), unit: .grams, amount: 200)]))
    }
}

struct RecipeDetailViewSelectorButtons: View {
    @Binding var isProductSelectorShowing: Bool
    @Binding var showPriceSetSelection: Bool
    @ObservedObject var recipe: Recipe
    
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
