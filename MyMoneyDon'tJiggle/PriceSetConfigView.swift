//
//  ContentView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 18.05.2022.
//

import SwiftUI

struct PriceSetConfigView: View {
    @EnvironmentObject var store: ProductStore
    @ObservedObject var priceSet: PriceSet
    
    @State private var isProductSelectorShowing = false
    private var selectedProducts: Binding<Set<Product>> {
        let originalSet = Set(self.priceSet.prices.map(\.product))
        return Binding {
            originalSet
        } set: { newSelectedProducts in
            let difference = originalSet.symmetricDifference(newSelectedProducts)
            for product in difference {
                if originalSet.contains(product) {
                    //product was removed
                    if let index = priceSet.prices.firstIndex(where: {
                        $0.product == product
                    }) {
                        priceSet.prices.remove(at: index)
                    }
                } else {
                    //product was added
                    priceSet.prices.append(ProductPrice(product: product))
                }
            }
        }

    }
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(priceSet.prices, id: \.product) { productPrice in
                    ProductPriceRow(productPrice: productPrice, currency: $priceSet.currency)
                        .fixedSize(horizontal: false, vertical: true)
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
}

struct ProductPriceRow: View {
    @ObservedObject var productPrice: ProductPrice
    @Binding var currency: Currency?
    @State private var cost: Double = 0.0
    
    private var product: Product {
        return self.productPrice.product
    }
    
    var measurementFormat: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        return formatter
    }
    private var currencyFormatter: Formatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = currency?.locale ?? Currency.rub.locale
        return formatter
    }
    
    var perUnitPrice: String {
        guard let currency = currency, let unit = productPrice.unit else {
            return "N/A"
        }
        let perUnit = productPrice.price / productPrice.quantity
        return String(format: "%.2f \(currency.symbol)/\(unit.description)", perUnit)
    }
    
    var body: some View {
        VStack(alignment: .leading){
            HStack {
                if case .system(let name) = product.icon {
                    Image(systemName: name)
                }
                Text(product.name)
                    .font(.title2)
                Spacer()
                Text(perUnitPrice)
                    .font(.title3)
                    .bold()
            }
            CurrencyTextField(value: $productPrice.price,
                              alignment: .left,
                              format: { double in
                currencyFormatter.string(for: double) ?? "N/A"
            })
                .font(.caption)
//                .background(Color.random)
                .frame(minWidth: 92)
            
            HStack {
                TextField("Кол.", value: $productPrice.quantity, formatter: NumberFormatter())
                    .frame(maxWidth: 80)
                    .padding(4)
                    .background(
                        Color(uiColor: UIColor.systemGray5)
                            .cornerRadius(8)
                )
                
                MenuPicker(selected: $productPrice.unit,
                           array: Unit.allCases,
                           defaultTitle: "ед.")
                    .multilineTextAlignment(.trailing)
//                    .frame(minWidth: 30)
//                    .background(Color.random)
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.random)
        )
//        .background(Color.random)
    }
}

extension Color {
    static var random: Color {
        let colors: [Color] = [.red, .blue, .yellow, .green, .purple, .brown, .cyan, .indigo, .orange, .mint, .pink, .gray, .teal]
        
        return colors.randomElement()!
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
        ].map { ProductPrice(product: $0) }
    )
    static var previews: some View {
        NavigationView {
            PriceSetConfigView(priceSet: priceSet)
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
