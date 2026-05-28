import SwiftUI

struct EditAssetView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel
    @Environment(\.dismiss) var dismiss

    let asset: Asset
    @State private var symbol: String
    @State private var nameField: String
    @State private var shares: String
    @State private var manualPrice: String
    @State private var marketType: MarketType

    init(asset: Asset) {
        self.asset = asset
        _symbol = State(initialValue: asset.symbol)
        _nameField = State(initialValue: asset.name)
        _shares = State(initialValue: String(asset.shares))
        _manualPrice = State(initialValue: asset.manualPrice.map { String($0) } ?? "")
        _marketType = State(initialValue: asset.marketType ?? .tw)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if asset.category == .stock || asset.category == .bond {
                        Picker(lang.market, selection: $marketType) {
                            ForEach(MarketType.allCases, id: \.self) { type in
                                Text(lang.localized(type.displayName)).tag(type)
                            }
                        }
                        TextField(lang.symbol, text: $symbol)
                            .textInputAutocapitalization(.characters)
                        TextField(lang.shares, text: $shares)
                            .keyboardType(.decimalPad)
                        TextField(lang.price, text: $manualPrice)
                            .keyboardType(.decimalPad)
                    } else {
                        TextField(lang.name, text: $nameField)
                        TextField(lang.amount, text: $shares)
                            .keyboardType(.decimalPad)
                    }
                }

                if let price = asset.marketPrice {
                    Section(lang.marketInfo) {
                        HStack {
                            Text(lang.marketPrice)
                            Spacer()
                            Text(portfolioVM.hideAssets
                                 ? PortfolioViewModel.maskedText
                                 : String(format: "%.2f", price))
                                .foregroundColor(.secondary)
                        }
                        if let valueTWD = asset.marketValueTWD {
                            HStack {
                                Text(lang.valueTWD)
                                Spacer()
                                Text(portfolioVM.hideAssets
                                     ? "NT$ \(PortfolioViewModel.maskedText)"
                                     : Rebalancer.formatCurrency(valueTWD))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(lang.edit)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lang.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lang.save) {
                        updateAsset()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func updateAsset() {
        guard let sharesValue = Double(shares), sharesValue > 0 else {
            portfolioVM.errorMessage = lang.invalidInput
            return
        }
        var updated = asset
        updated.symbol = symbol.uppercased()
        updated.name = nameField.isEmpty ? symbol.uppercased() : nameField
        updated.shares = sharesValue
        updated.manualPrice = Double(manualPrice)
        updated.marketType = (asset.category == .stock || asset.category == .bond) ? marketType : nil

        Task {
            await portfolioVM.updateAsset(updated)
            dismiss()
        }
    }
}
