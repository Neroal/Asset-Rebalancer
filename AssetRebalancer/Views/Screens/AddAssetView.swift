import SwiftUI

struct AddAssetView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel
    @Environment(\.dismiss) var dismiss

    @State private var category: AssetCategory = .stock
    @State private var symbol = ""
    @State private var nameField = ""
    @State private var shares = ""
    @State private var manualPrice = ""
    @State private var marketType: MarketType = .tw

    var body: some View {
        NavigationStack {
            Form {
                // Category Picker
                Section {
                    Picker(lang.language == .zh ? "類別" : "Category", selection: $category) {
                        ForEach(AssetCategory.allCases) { cat in
                            Text(lang.localized(cat.displayName))
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Fields based on category
                Section {
                    if category == .stock || category == .bond {
                        Picker(lang.market, selection: $marketType) {
                            ForEach(MarketType.allCases, id: \.self) { type in
                                Text(lang.localized(type.displayName)).tag(type)
                            }
                        }

                        TextField(lang.symbol, text: $symbol)
                            .textInputAutocapitalization(.characters)

                        TextField(lang.shares, text: $shares)
                            .keyboardType(.decimalPad)

                        TextField("\(lang.price) (\(lang.language == .zh ? "選填" : "Optional"))",
                                  text: $manualPrice)
                            .keyboardType(.decimalPad)
                    } else {
                        TextField(lang.name, text: $nameField)
                        TextField("\(lang.amount) (TWD)", text: $shares)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(lang.addAsset)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lang.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.save) {
                        saveAsset()
                    }
                    .fontWeight(.semibold)
                    .disabled(category == .cash ? nameField.isEmpty : symbol.isEmpty)
                }
            }
        }
    }

    private func saveAsset() {
        let sharesValue = Double(shares) ?? 0
        guard sharesValue > 0 else {
            portfolioVM.errorMessage = lang.invalidInput
            return
        }
        let priceValue = Double(manualPrice)
        if let price = priceValue, price < 0 {
            portfolioVM.errorMessage = lang.invalidInput
            return
        }

        let asset = Asset(
            category: category,
            symbol: (category == .stock || category == .bond) ? symbol.uppercased() : (nameField.isEmpty ? (lang.language == .zh ? "現金" : "Cash") : nameField),
            name: nameField.isEmpty ? symbol.uppercased() : nameField,
            shares: sharesValue,
            manualPrice: priceValue,
            marketType: (category == .stock || category == .bond) ? marketType : nil
        )

        Task {
            await portfolioVM.addAsset(asset)
            dismiss()
        }
    }
}
