//
//  CurrencyTextField.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 19.05.2022.
//

import UIKit
import SwiftUI

class CurrencyUITextField: UITextField {
    var onDeleteBackwards: (CurrencyUITextField) -> () = {_ in }
    
    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func deleteBackward() {
        onDeleteBackwards(self)
    }
    
    private func setupViews() {
        tintColor = .clear
        textAlignment = .right
        font = .systemFont(ofSize: 40, weight: .regular)
    }

    
    var textValue: String {
        return text ?? ""
    }
    
    func currency(from double: Double, using formatter: NumberFormatter) -> String {
        return formatter.string(for: double) ?? ""
    }

}


extension StringProtocol where Self: RangeReplaceableCollection {
    var digits: Self { filter (\.isWholeNumber) }
}

extension String {
    var decimal: Decimal { Decimal(string: digits) ?? 0 }
}

extension LosslessStringConvertible {
    var string: String { .init(self) }
}

extension Decimal {
    func fraction(digits: Int) -> Decimal {
        return self / pow(10, digits)
    }
    
    var doubleValue: Double {
        return (self as NSDecimalNumber).doubleValue
    }
}


struct CurrencyTextField: UIViewRepresentable {
    typealias UIViewType = CurrencyUITextField
    
    @Binding var currency: Currency?
    @Binding var value: Double

    private var formatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = currency?.locale ?? Currency.rub.locale
        return formatter
    }

    func makeUIView(context: Context) -> CurrencyUITextField {
        let textField = CurrencyUITextField()
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldTextDidChange), for: .editingChanged)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.resetSelection), for: .allTouchEvents)
        textField.onDeleteBackwards = context.coordinator.onDeleteBackwards
        context.coordinator.reformatText(double: value, textField: textField, formatter: formatter)
        context.coordinator.resetSelection(textField)
        textField.becomeFirstResponder() // when textField re-renders, it's not the first responder anymore, so we need to force it to become the first responder again, so the user doesn't have to select the text field after every entry, fuck me
        textField.keyboardType = .numberPad
        return textField
    }
    
    func updateUIView(_ uiView: CurrencyUITextField, context: Context) {
//        context.coordinator.reformatText(double: value, textField: uiView, formatter: formatter)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    
    class Coordinator {
        let currencyTextField: CurrencyTextField
        
        init(_ textField: CurrencyTextField) {
            self.currencyTextField = textField
        }
        
        @objc func textFieldTextDidChange(_ textField: CurrencyUITextField) {
            let decimal = textField.textValue
                .decimal
                .fraction(digits: currencyTextField.formatter.maximumFractionDigits)
                .doubleValue
            
            currencyTextField.value = decimal
        }
        
        func reformatText(double: Double, textField: CurrencyUITextField, formatter: NumberFormatter) {
            textField.text = textField.currency(from: double, using: formatter)
        }
        
        func onDeleteBackwards(_ textField: CurrencyUITextField) {
            let droppedDigits = textField.textValue.digits.dropLast().string
            let decimal = Decimal(string: droppedDigits)!
                .fraction(digits: currencyTextField.formatter.maximumFractionDigits)
                .doubleValue
            currencyTextField.value = decimal
        }
        
        @objc func resetSelection(_ textField: CurrencyUITextField) {
            textField.selectedTextRange = textField.textRange(from: textField.endOfDocument, to: textField.endOfDocument)
        }

    }
}
