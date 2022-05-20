//
//  ProductBankView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 19.05.2022.
//

import SwiftUI


struct ProductBank: View {
    @EnvironmentObject var store: ProductStore
    @State private var newProductName: String = ""
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? = UIImage(systemName: "photo.on.rectangle.angled")!.withRenderingMode(.alwaysTemplate)
    @State var x: CGFloat = 0
    
    var body: some View {
        NavigationView {
            VStack {
                List(store.bank, id: \.self) { product in
                    HStack {
                        Group {
                            if case .system(let name) = product.icon {
                                Image(systemName: name)
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .scaledToFill()
                            } else if case .image(let uiImage) = product.icon {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .scaledToFill()
                            }
                        }
                        .cornerRadius(8)
                        Text(product.name)
                    }
                }
                HStack {
                    if let inputImage = inputImage {
                        Image(uiImage: inputImage)
                            .resizable()
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                            .frame(width: 44, height: 44)
                            .scaledToFill()
                            .onTapGesture {
                                self.showingImagePicker.toggle()
                            }
                    }

                    TextField("Название:", text: $newProductName, onCommit: addNewProduct)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Добавить") {
                        addNewProduct()
                    }
                    
                }
                .padding()
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $inputImage)
                }
            }
            .navigationTitle("Банк Продуктов")
        }
    }
    
    func addNewProduct() {
        guard let inputImage = inputImage, !newProductName.isEmpty else {
            return
        }
        store.addNewProduct(newProductName, icon: inputImage)
        self.newProductName = ""
    }
}

struct ProductBankView_Preview: PreviewProvider {
    private static let store = ProductStore()
    static var previews: some View {
        ProductBank()
            .environmentObject(store)
    }
}
