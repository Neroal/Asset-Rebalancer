import SwiftUI

struct DeviationRow: View {
    let category: AssetCategory
    let current: Double
    let target: Double
    let deviation: Double
    var threshold: Double = 5.0
    var language: AppLanguage = .zh

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(category.swiftUIColor)
                    .frame(width: 10, height: 10)

                Text(language == .zh ? category.displayName.zh : category.displayName.en)
                    .font(.subheadline)

                Spacer()

                Text(Rebalancer.formatPercentage(current))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("/ \(Rebalancer.formatPercentage(target))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(deviation >= 0 ? "+\(Rebalancer.formatPercentage(deviation))" : Rebalancer.formatPercentage(deviation))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(abs(deviation) > threshold ? .red : .secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    // Current value
                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.swiftUIColor)
                        .frame(width: max(0, geo.size.width * current / 100), height: 6)

                    // Target marker
                    Rectangle()
                        .fill(Color.primary.opacity(0.5))
                        .frame(width: 2, height: 12)
                        .offset(x: geo.size.width * target / 100 - 1)
                }
            }
            .frame(height: 12)
        }
    }
}
