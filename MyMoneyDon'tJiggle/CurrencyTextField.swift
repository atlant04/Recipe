//
//  CurrencyTextField.swift
//  MyMoneyDon'tJiggle
//
//  Created by Alena Tochilkina on 19.05.2022.
//

import UIKit
import SwiftUI

class CurrencyUITextField: UITextField {
    
    var formatter: NumberFormatter
    private let coordinator: CurrencyTextField.Coordinator
    
    init(formatter: NumberFormatter, coordinator: CurrencyTextField.Coordinator) {
        self.formatter = formatter
        self.coordinator = coordinator
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        addTarget(coordinator, action: #selector(CurrencyTextField.Coordinator.editingChanged), for: .editingChanged)
        addTarget(self, action: #selector(resetSelection), for: .allTouchEvents)
        keyboardType = .numberPad
        textAlignment = .right
        sendActions(for: .editingChanged)
    }
    
    override func deleteBackward() {
        text = textValue.digits.dropLast().string
        sendActions(for: .editingChanged)
    }
    
    private func setupViews() {
        tintColor = .clear
        font = .systemFont(ofSize: 40, weight: .regular)
    }
    
    @objc func resetSelection() {
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }
    
    private var textValue: String {
        return text ?? ""
    }
    
    func formatText(double: Double? = nil) {
        if let value = double {
            self.text = formatter.string(for: value)
        } else {
            self.text = currency(from: decimal)
        }
    }

    var doubleValue: Double {
      return (decimal as NSDecimalNumber).doubleValue
    }

    private var decimal: Decimal {
      return textValue.decimal / pow(10, formatter.maximumFractionDigits)
    }
    
    private func currency(from decimal: Decimal) -> String {
        return formatter.string(for: decimal) ?? ""
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


struct CurrencyTextField: UIViewRepresentable {
    typealias UIViewType = CurrencyUITextField
    
    let numberFormatter: NumberFormatter
    @Binding var value: Double
    
    init(numberFormatter: NumberFormatter, value: Binding<Double>) {
        self.numberFormatter = numberFormatter
        self._value = value
    }
    
    func makeUIView(context: Context) -> CurrencyUITextField {
        let currencyField = CurrencyUITextField(formatter: numberFormatter, coordinator: context.coordinator)
        return currencyField
    }
    
    func updateUIView(_ uiView: CurrencyUITextField, context: Context) {
        uiView.formatter = self.numberFormatter
        uiView.formatText()
        uiView.resetSelection()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self.$value)
    }
    
    
    class Coordinator {
        @Binding var value: Double
        
        init(_ binding: Binding<Double>) {
            self._value = binding
        }
        
        @objc func editingChanged(_ textField: UITextField) {
            guard let currencyField = textField as? CurrencyUITextField else { return }
            DispatchQueue.main.async { [unowned self] in
                value = currencyField.doubleValue
                currencyField.formatText()
                currencyField.resetSelection()
            }
        }
    }
}
