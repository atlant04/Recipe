//
//  MyMoneyDon_tJiggleApp.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 18.05.2022.
//

import SwiftUI


class Persistance {
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
    
    static func save(store: ProductStore, completion: @escaping (Result<Data, Error>)->Void) {
            DispatchQueue.global(qos: .background).async {
                do {
                    let data = try JSONEncoder().encode(store)
                    let outfile = try fileURL()
                    try data.write(to: outfile)
                    DispatchQueue.main.async {
                        completion(.success(data))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
}

@main
struct MyMoneyDon_tJiggleApp: App {
    @StateObject var store = ProductStore()
    @Environment(\.scenePhase) private var scenePhase
    
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
            .onAppear {
                Persistance.load { result in
                    switch result {
                    case .success(let store):
                        self.store.currentCurrency = store.currentCurrency
                        self.store.priceSets = store.priceSets
                        self.store.productBank = store.productBank
                        self.store.recipeList = store.recipeList
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            .environmentObject(store)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                Persistance.save(store: store) { result in
                    switch result {
                    case .success(let data): print(String(data: data, encoding: .utf8))
                    case .failure(let error): print(error.localizedDescription)
                    }
                }
            }
        }
    }
}
