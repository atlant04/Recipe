//
//  MyMoneyDon_tJiggleApp.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 18.05.2022.
//

import SwiftUI

@main
struct MyMoneyDon_tJiggleApp: App {
    @StateObject var store = ProductStore()
    var body: some Scene {
        WindowGroup {
            TabView {
                RecipeListView()
                    .tabItem {
                        Label("Рецепты", systemImage: "list.bullet.rectangle")
                    }

                ProductBank()
                    .tabItem {
                        Label("Банк", systemImage: "lock")
                    }
                
                PriceSetView()
                    .tabItem {
                        Label("Наборы цен", systemImage: "dollarsign.circle")
                    }
                
            }
            .environmentObject(store)
        }
    }
}
