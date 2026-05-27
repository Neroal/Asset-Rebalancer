import SwiftUI

struct AssetsView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel
    @State private var showAddSheet = false
    @State private var editingAsset: Asset?
    @State private var assetToDelete: Asset?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(AssetCategory.allCases) { category in
                    let categoryAssets = portfolioVM.assets.filter { $0.category == category }
                    if !categoryAssets.isEmpty {
                        Section {
                            ForEach(categoryAssets) { asset in
                                AssetRowView(asset: asset, hideAssets: portfolioVM.hideAssets)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingAsset = asset
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            assetToDelete = asset
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label(lang.delete, systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Text(lang.localized(category.displayName))
                                Spacer()
                                let subtotal = categoryAssets.reduce(0) {
                                    $0 + ($1.marketValueTWD ?? $1.displayValue)
                                }
                                Text(portfolioVM.hideAssets
                                     ? "NT$ \(PortfolioViewModel.maskedText)"
                                     : Rebalancer.formatCurrency(subtotal))
                                    .font(.caption)
                            }
                        }
                    }
                }

                if portfolioVM.assets.isEmpty && !portfolioVM.isLoading {
                    ContentUnavailableView {
                        Label(lang.addAsset, systemImage: "plus.circle")
                    } description: {
                        Text(lang.emptyAssetHint)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showAddSheet = true
                    }
                }
            }
            .navigationTitle(lang.tabAssets)
            .alert(lang.deleteConfirmTitle, isPresented: $showDeleteConfirmation) {
                Button(lang.cancel, role: .cancel) {
                    assetToDelete = nil
                }
                Button(lang.delete, role: .destructive) {
                    if let asset = assetToDelete {
                        Task {
                            await portfolioVM.deleteAsset(asset.id)
                        }
                        assetToDelete = nil
                    }
                }
            } message: {
                Text(lang.deleteConfirmMessage)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddAssetView()
            }
            .sheet(item: $editingAsset) { asset in
                EditAssetView(asset: asset)
            }
            .refreshable {
                await portfolioVM.refreshPrices()
            }
        }
    }
}

// MARK: - Add Asset View
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

// MARK: - Edit Asset View
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
        updated.updatedAt = Date()

        Task {
            await portfolioVM.updateAsset(updated)
            dismiss()
        }
    }
}
