import SwiftUI

struct AssetsView: View {
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel
    @State private var showAddSheet = false
    @State private var editingAsset: Asset?

    var body: some View {
        NavigationStack {
            List {
                ForEach(AssetCategory.allCases) { category in
                    let categoryAssets = portfolioVM.assets.filter { $0.category == category }
                    if !categoryAssets.isEmpty {
                        Section {
                            ForEach(categoryAssets) { asset in
                                AssetRowView(asset: asset)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingAsset = asset
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task {
                                                await portfolioVM.deleteAsset(asset.id)
                                            }
                                        } label: {
                                            Label(lang.delete, systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            HStack {
                                Text(lang.language == .zh
                                     ? category.displayName.zh
                                     : category.displayName.en)
                                Spacer()
                                let subtotal = categoryAssets.reduce(0) {
                                    $0 + ($1.marketValueTWD ?? $1.displayValue)
                                }
                                Text(Rebalancer.formatCurrency(subtotal))
                                    .font(.caption)
                            }
                        }
                    }
                }

                if portfolioVM.assets.isEmpty && !portfolioVM.isLoading {
                    ContentUnavailableView {
                        Label(lang.addAsset, systemImage: "plus.circle")
                    } description: {
                        Text(lang.language == .zh
                             ? "點擊右上角新增你的第一筆資產"
                             : "Tap + to add your first asset")
                    }
                }
            }
            .navigationTitle(lang.tabAssets)
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
                            Text(lang.language == .zh ? cat.displayName.zh : cat.displayName.en)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Fields based on category
                Section {
                    if category == .stock {
                        Picker(lang.market, selection: $marketType) {
                            ForEach(MarketType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }

                        TextField(lang.symbol, text: $symbol)
                            .textInputAutocapitalization(.characters)

                        TextField(lang.shares, text: $shares)
                            .keyboardType(.decimalPad)

                        TextField("\(lang.price) (\(lang.language == .zh ? "選填" : "Optional"))",
                                  text: $manualPrice)
                            .keyboardType(.decimalPad)
                    } else if category == .bond {
                        TextField(lang.name, text: $nameField)
                        TextField("\(lang.amount) (TWD)", text: $shares)
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
                    .disabled(symbol.isEmpty && nameField.isEmpty)
                }
            }
        }
    }

    private func saveAsset() {
        let sharesValue = Double(shares) ?? 0
        let priceValue = Double(manualPrice)

        let asset = Asset(
            category: category,
            symbol: category == .stock ? symbol.uppercased() : (nameField.isEmpty ? (lang.language == .zh ? "現金" : "Cash") : nameField),
            name: nameField.isEmpty ? symbol.uppercased() : nameField,
            shares: sharesValue,
            manualPrice: priceValue,
            marketType: category == .stock ? marketType : nil
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
                    if asset.category == .stock {
                        Picker(lang.market, selection: $marketType) {
                            ForEach(MarketType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
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
                    Section(lang.language == .zh ? "市場資訊" : "Market Info") {
                        HStack {
                            Text(lang.language == .zh ? "市場價格" : "Market Price")
                            Spacer()
                            Text(String(format: "%.2f", price))
                                .foregroundColor(.secondary)
                        }
                        if let valueTWD = asset.marketValueTWD {
                            HStack {
                                Text(lang.language == .zh ? "市值(TWD)" : "Value (TWD)")
                                Spacer()
                                Text(Rebalancer.formatCurrency(valueTWD))
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
        var updated = asset
        updated.symbol = symbol.uppercased()
        updated.name = nameField.isEmpty ? symbol.uppercased() : nameField
        updated.shares = Double(shares) ?? 0
        updated.manualPrice = Double(manualPrice)
        updated.marketType = asset.category == .stock ? marketType : nil
        updated.updatedAt = Date()

        Task {
            await portfolioVM.updateAsset(updated)
            dismiss()
        }
    }
}
