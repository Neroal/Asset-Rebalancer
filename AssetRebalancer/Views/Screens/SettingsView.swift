import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var portfolioVM: PortfolioViewModel
    @EnvironmentObject var lang: LanguageViewModel

    var body: some View {
        NavigationStack {
            Form {
                // Account
                Section(lang.account) {
                    if let user = authVM.user {
                        HStack {
                            if let photoURL = user.photoURL {
                                AsyncImage(url: photoURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName ?? "")
                                    .font(.headline)
                                Text(user.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Target Allocation
                Section(lang.targetAllocationSetting) {
                    AllocationSlider(
                        label: lang.stocks,
                        value: $portfolioVM.targetAllocation.stock,
                        color: .blue
                    )
                    AllocationSlider(
                        label: lang.bonds,
                        value: $portfolioVM.targetAllocation.bond,
                        color: .green
                    )
                    AllocationSlider(
                        label: lang.cash,
                        value: $portfolioVM.targetAllocation.cash,
                        color: .orange
                    )

                    let total = portfolioVM.targetAllocation.stock +
                                portfolioVM.targetAllocation.bond +
                                portfolioVM.targetAllocation.cash
                    HStack {
                        Text(lang.language == .zh ? "合計" : "Total")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(Rebalancer.formatPercentage(total))
                            .foregroundColor(abs(total - 100) < 0.01 ? .green : .red)
                            .fontWeight(.semibold)
                    }

                    Button(lang.save) {
                        Task { await portfolioVM.saveTarget() }
                    }
                    .disabled(!portfolioVM.targetAllocation.isValid)
                }

                // Deviation Threshold
                Section(lang.deviationThreshold) {
                    VStack {
                        HStack {
                            Text(Rebalancer.formatPercentage(portfolioVM.deviationThreshold))
                                .font(.headline)
                            Spacer()
                        }
                        Slider(value: $portfolioVM.deviationThreshold, in: 1...20, step: 0.5) {
                            Text(lang.deviationThreshold)
                        }
                        .onChange(of: portfolioVM.deviationThreshold) { _, _ in
                            Task { await portfolioVM.saveThreshold() }
                        }
                    }
                }

                // Language
                Section(lang.language_) {
                    Picker(lang.language_, selection: $lang.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }

                // Sign Out
                Section {
                    Button(role: .destructive) {
                        authVM.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text(lang.signOut)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle(lang.tabSettings)
        }
    }
}

// MARK: - Allocation Slider
struct AllocationSlider: View {
    let label: String
    @Binding var value: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(label)
                Spacer()
                Text(Rebalancer.formatPercentage(value))
                    .fontWeight(.medium)
                    .monospacedDigit()
            }
            Slider(value: $value, in: 0...100, step: 1)
                .tint(color)
        }
    }
}
