//
//  ContentView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 18.05.2022.
//

import SwiftUI

struct PriceSetConfigView: View {
    @EnvironmentObject var store: ProductStore
    @Binding var priceSet: PriceSet
    @State private var isProductSelectorShowing = false
    private var selectedProducts: Binding<Set<Product>> {
        Binding {
            Set(self.priceSet.prices.map(\.product))
        } set: { newSelectedProducts in
            let selectedPrices = newSelectedProducts.map { ProductPrice(product: $0, price: 0.0) }
            self.priceSet.prices = Array(Set(selectedPrices))
        }

    }
    
    var body: some View {
        VStack {
            ForEach($priceSet.prices, id: \.self) { $productPrice in
                ProductPriceRow(productPrice: $productPrice, currency: $priceSet.currency)
                    .frame(maxHeight: 60)
                    .padding(.horizontal)
            }
            
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
                    Text("Добавить цену продукта")
                        .foregroundColor(.blue)
                }
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .sheet(isPresented: $isProductSelectorShowing) {
            ProductSelector(allItems: store.productBank,
                            selectedProducts: selectedProducts,
                            isProductSelectorShowing: $isProductSelectorShowing)
        }
        .navigationBarTitle(priceSet.name)
        .toolbar(content: {
            MenuPicker(selected: $priceSet.currency, array: Currency.allCases, defaultTitle: "Валюта")
        })
    }
}

struct ProductPriceRow: View {
    @Binding var productPrice: ProductPrice
    @Binding var currency: Currency?
    @State private var cost: Double = 0.0
    
    private var product: Product {
        return self.productPrice.product
    }
    
    var body: some View {
        HStack {
            if case .system(let name) = product.icon {
                Image(systemName: name)
            }
            Text("\(Int(cost))")
            Spacer()
            CurrencyTextField(currency: $currency, value: $productPrice.price)
                .font(.caption)
                .frame(minWidth: 92, alignment: .trailing)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @State private static var priceSet = PriceSet(
        name: "My set",
        prices: [
            Product(icon: .system("trash"), name: "Milk"),
            Product(icon: .system("powerplug"), name: "Sugar"),
            Product(icon: .system("dice"), name: "Cream cheese"),
            Product(icon: .system("lock"), name: "Flour")
        ].map { ProductPrice(product: $0, price: 0.0) }
    )
    static var previews: some View {
        NavigationView {
            PriceSetConfigView(priceSet: $priceSet)
        }
    }
}

@available (iOS 14.0, *)
public struct MenuPicker<T>: View where T: Hashable & CustomStringConvertible {
    
    @Binding var selected: T?
    var array: [T]
    var defaultTitle: String
    
    var title: String {
        selected?.description ?? defaultTitle
    }
    
    public init(selected: Binding<T?>, array: [T], defaultTitle: String = "") {
        self._selected = selected
        self.array = array
        self.defaultTitle = defaultTitle
    }
    
    public var body: some View {
        Menu(self.title, content: {
            ForEach(array, id: \.self) { item in
                Button(action: {
                    selected = item
                }, label: {
                    view(for: item)
                })
            }
        })
    }

    
    @ViewBuilder func view(for item: T) -> some View {
        if let selected = self.selected,
           selected == item {
            HStack {
                Image(systemName: "checkmark")
                Text(selected.description)
            }
        } else {
            Text(item.description)
        }
    }
}
