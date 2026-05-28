import SwiftUI

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
