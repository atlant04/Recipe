//
//  PriceSetSelectionView.swift
//  MyMoneyDon'tJiggle
//
//  Created by Maksim Tochilkin on 5/25/22.
//

import SwiftUI

struct PriceSetSelectionView: View {
    @EnvironmentObject var store: ProductStore
    
    @Binding var selectedPriceSet: PriceSet?
    @Binding var showPriceSetSelection: Bool
    
    var body: some View {
        NavigationView {
            List(store.priceSets, selection: $selectedPriceSet) { priceSet in
                SelectableRow(selectable: priceSet,
                              selectedRow: $selectedPriceSet) {
                    Text(priceSet.name)
                }
                .onSelection {
                    showPriceSetSelection = false
                }
            }
            .navigationTitle("Выбрать набор")
        }
    }
}

struct SelectableRow<Content, SelectedContent>: View where Content: View, SelectedContent: Equatable {
    private let content: Content
    private let selectable: SelectedContent
    private let onSelection: () -> ()
    @Binding private var selectedRow: SelectedContent?
    
    init(selectable: SelectedContent,
         selectedRow: Binding<SelectedContent?>,
         onSelection: @escaping () -> () = { },
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.selectable = selectable
        self.onSelection = onSelection
        self._selectedRow = selectedRow
    }
    
    var body: some View {
        HStack() {
            content
            if let selectedRow = selectedRow,
                selectedRow == selectable {
                Image(systemName: "checkmark")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .border(Color.red)
        .onTapGesture {
            print("here")
            self.selectedRow = selectable
            onSelection()
        }
    }
    
    func onSelection(_ code: @escaping () -> ()) -> Self {
        return SelectableRow(selectable: selectable, selectedRow: $selectedRow, onSelection: code, content: { return content })
    }
}

struct PriceSetSelectionView_Previews: PreviewProvider {
    @State private static var selectedPriceSet: PriceSet?
    private static let store = ProductStore()

    static var previews: some View {
        PriceSetSelectionView(selectedPriceSet: $selectedPriceSet, showPriceSetSelection: .constant(false))
            .environmentObject(store)
    }
}
